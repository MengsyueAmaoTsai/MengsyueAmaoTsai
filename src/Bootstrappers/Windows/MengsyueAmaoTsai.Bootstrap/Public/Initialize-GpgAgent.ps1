<#
.SYNOPSIS
    確保 Gpg4win 已安裝、gpg-agent 快取設定已套用，並讓 gpg-agent 處於執行中。

.DESCRIPTION
    未安裝時以 winget 安裝。快取設定採附加式寫入，只補上缺少的行，不覆蓋既有的
    gpg-agent.conf 內容。最後重啟 gpg-agent 讓設定生效。
#>
function Initialize-GpgAgent {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$PackageId = 'GnuPG.Gpg4win',

        [string]$ConfigurationDirectory = (Join-Path $env:APPDATA 'gnupg'),

        [int]$DefaultCacheTtlSeconds = 86400,

        [int]$MaxCacheTtlSeconds = 604800
    )

    # 1. 確保 Gpg4win 已安裝
    if (Get-Command gpg.exe -ErrorAction SilentlyContinue) {
        Write-BootstrapperStatus -Level OK -Message 'Gpg4win installed'
    }
    elseif ($PSCmdlet.ShouldProcess($PackageId, 'Install package')) {
        Write-BootstrapperStatus -Level INFO -Message 'Installing Gpg4win'

        try {
            winget install --id $PackageId -e -h --accept-source-agreements --accept-package-agreements
            Assert-NativeCommandSuccess -Activity 'winget install' -ExitCode $LASTEXITCODE
            Write-BootstrapperStatus -Level OK -Message 'Gpg4win installed'
        }
        catch {
            throw "Failed to install Gpg4win: $($_.Exception.Message)"
        }
    }

    # 2. gpg-agent 快取 TTL
    $cacheSettings = @(
        "default-cache-ttl $DefaultCacheTtlSeconds"
        "max-cache-ttl $MaxCacheTtlSeconds"
    )
    $agentConfigurationPath = Join-Path $ConfigurationDirectory 'gpg-agent.conf'
    $configurationChanged = $false

    if (-not (Test-Path -LiteralPath $ConfigurationDirectory)) {
        New-Item -Path $ConfigurationDirectory -ItemType Directory -Force | Out-Null
    }

    # 只補上缺少的行，避免覆蓋使用者自訂設定
    if (-not (Test-Path -LiteralPath $agentConfigurationPath)) {
        Set-Content -LiteralPath $agentConfigurationPath -Value $cacheSettings -Encoding UTF8
        $configurationChanged = $true
    }
    else {
        $existing = @(Get-Content -LiteralPath $agentConfigurationPath)
        foreach ($line in $cacheSettings) {
            if ($existing -notcontains $line) {
                Add-Content -LiteralPath $agentConfigurationPath -Value $line
                $configurationChanged = $true
            }
        }
    }

    if ($configurationChanged) {
        Write-BootstrapperStatus -Level OK -Message 'GPG agent cache settings updated'
    }
    else {
        Write-BootstrapperStatus -Level OK -Message 'GPG agent cache settings already configured'
    }

    # 3. 重啟 gpg-agent 讓設定生效
    if (-not $PSCmdlet.ShouldProcess('gpg-agent', 'Restart agent')) {
        return
    }

    if (Get-Process gpg-agent -ErrorAction SilentlyContinue) {
        gpgconf --kill gpg-agent
        Assert-NativeCommandSuccess -Activity 'Stop GPG agent' -ExitCode $LASTEXITCODE
    }

    try {
        gpgconf --launch gpg-agent
        Assert-NativeCommandSuccess -Activity 'Launch GPG agent' -ExitCode $LASTEXITCODE

        Start-Sleep -Seconds 1

        if (-not (Get-Process gpg-agent -ErrorAction SilentlyContinue)) {
            throw 'GPG agent did not start.'
        }

        Write-BootstrapperStatus -Level OK -Message 'GPG agent running'
    }
    catch {
        throw "Failed to start GPG agent: $($_.Exception.Message)"
    }
}
