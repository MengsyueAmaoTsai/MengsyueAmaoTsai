<#
.SYNOPSIS
    確保 OpenSSH Authentication Agent 在執行中，並載入指定的私鑰。

.DESCRIPTION
    服務被停用時改為 Manual 再啟動。載入金鑰前先比對 agent 內既有的 fingerprint，
    已載入就不重複要求密碼。服務或金鑰不存在時回報 SKIP / WARN 並結束，不視為錯誤。
#>
function Initialize-SshAgent {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ServiceName = 'ssh-agent',

        [string]$KeyPath = (Join-Path $env:USERPROFILE '.ssh\id_rsa')
    )

    # 1. ssh-agent 服務
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-BootstrapperStatus -Level SKIP -Message 'OpenSSH Authentication Agent service not found'
        return
    }

    if ($service.StartType -eq 'Disabled') {
        Write-BootstrapperStatus -Level INFO -Message 'Enabling SSH agent service'
        Set-Service -Name $ServiceName -StartupType Manual
    }

    if ($service.Status -ne 'Running') {
        Write-BootstrapperStatus -Level INFO -Message 'Starting SSH agent'

        if ($PSCmdlet.ShouldProcess($ServiceName, 'Start service')) {
            try {
                Start-Service -Name $ServiceName
                Start-Sleep -Seconds 1

                if ((Get-Service -Name $ServiceName).Status -ne 'Running') {
                    throw 'SSH agent did not reach the Running state.'
                }

                Write-BootstrapperStatus -Level OK -Message 'SSH agent started'
            }
            catch {
                throw "Failed to start SSH agent: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-BootstrapperStatus -Level OK -Message 'SSH agent already running'
    }

    # 2. 載入私鑰
    if (-not (Test-Path -LiteralPath $KeyPath)) {
        Write-BootstrapperStatus -Level WARN -Message 'SSH key not found' -Detail $KeyPath
        return
    }

    $keyName = Split-Path $KeyPath -Leaf
    $loadedKeys = ssh-add -l 2>$null
    $publicKeyPath = "$KeyPath.pub"
    $keyFingerprint = $null

    if (Test-Path -LiteralPath $publicKeyPath) {
        $publicKeyInfo = ssh-keygen -lf $publicKeyPath 2>$null
        if ($LASTEXITCODE -eq 0 -and $publicKeyInfo -match 'SHA256:\S+') {
            $keyFingerprint = $Matches[0]
        }
    }

    # 有 fingerprint 就比對 fingerprint，否則退而比對檔名
    $isLoaded = if ($keyFingerprint) {
        [bool]($loadedKeys -match [regex]::Escape($keyFingerprint))
    }
    else {
        [bool]($loadedKeys -and $loadedKeys -match [regex]::Escape($keyName))
    }

    if ($isLoaded) {
        Write-BootstrapperStatus -Level OK -Message "SSH key already loaded ($keyName)"
        return
    }

    Write-BootstrapperStatus -Level INFO -Message "Loading SSH key ($keyName)"

    if (-not $PSCmdlet.ShouldProcess($KeyPath, 'Add key to SSH agent')) {
        return
    }

    try {
        ssh-add $KeyPath
        Assert-NativeCommandSuccess -Activity 'ssh-add' -ExitCode $LASTEXITCODE
        Write-BootstrapperStatus -Level OK -Message 'SSH key loaded'
    }
    catch {
        throw "Failed to load SSH key: $($_.Exception.Message)"
    }
}
