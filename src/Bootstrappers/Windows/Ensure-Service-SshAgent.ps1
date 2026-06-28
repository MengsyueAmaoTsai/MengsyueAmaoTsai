. "$PSScriptRoot\Bootstrapper.Output.ps1"

$serviceName = "ssh-agent"
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa" 

# 1: 檢查 ssh-agent service
$service = Get-Service $serviceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-BootstrapperStatus -Level SKIP -Message 'OpenSSH Authentication Agent service not found'
    return
}

# 如果 Disabled 改成 Manual
if ($service.StartType -eq "Disabled") {
    Write-BootstrapperStatus -Level INFO -Message 'Enabling SSH agent service'
    Set-Service -Name $serviceName -StartupType Manual
}

if ($service.Status -ne "Running") {
    Write-BootstrapperStatus -Level INFO -Message 'Starting SSH agent'
    try {
        Start-Service $serviceName
        Start-Sleep -Seconds 1

        if ((Get-Service $serviceName).Status -eq "Running") {
            Write-BootstrapperStatus -Level OK -Message 'SSH agent started'
        }
        else {
            throw 'SSH agent did not reach the Running state.'
        }
    }
    catch {
        throw "Failed to start SSH agent: $($_.Exception.Message)"
    }
}
else {
    Write-BootstrapperStatus -Level OK -Message 'SSH agent already running'
}

# 2: 自動加入 SSH key
if (-not (Test-Path $sshKeyPath)) {
    Write-BootstrapperStatus -Level WARN -Message 'SSH key not found' -Detail $sshKeyPath
    return
}

# 先檢查 key 是否已經在 agent 裡
$keyList = ssh-add -l 2>$null
$publicKeyPath = "$sshKeyPath.pub"
$keyFingerprint = $null

if (Test-Path $publicKeyPath) {
    $publicKeyInfo = & ssh-keygen -lf $publicKeyPath 2>$null
    if ($LASTEXITCODE -eq 0 -and $publicKeyInfo -match 'SHA256:\S+') {
        $keyFingerprint = $Matches[0]
    }
}

$keyLoaded = if ($keyFingerprint) {
    $keyList -match [regex]::Escape($keyFingerprint)
}
else {
    $keyList -and $keyList -match [regex]::Escape((Split-Path $sshKeyPath -Leaf))
}

if ($keyLoaded) {
    Write-BootstrapperStatus -Level OK -Message "SSH key already loaded ($(Split-Path $sshKeyPath -Leaf))"
}
else {
    Write-BootstrapperStatus -Level INFO -Message "Loading SSH key ($(Split-Path $sshKeyPath -Leaf))"
    try {
        & ssh-add $sshKeyPath
        if ($LASTEXITCODE -ne 0) {
            throw "ssh-add exited with code $LASTEXITCODE."
        }

        Write-BootstrapperStatus -Level OK -Message 'SSH key loaded'
    }
    catch {
        throw "Failed to load SSH key: $($_.Exception.Message)"
    }
}
