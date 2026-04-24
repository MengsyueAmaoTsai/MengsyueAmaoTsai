$serviceName = "ssh-agent"
$sshKeyPath = "$env:USERPROFILE\.ssh\id_rsa" 

# 1: 檢查 ssh-agent service
$service = Get-Service $serviceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Service $serviceName not found." -ForegroundColor Red
    return
}

# 如果 Disabled 改成 Manual
if ($service.StartType -eq "Disabled") {
    Write-Host "$serviceName is disabled. Setting StartupType to Manual." -ForegroundColor Yellow
    Set-Service -Name $serviceName -StartupType Manual
}

if ($service.Status -ne "Running") {
    Write-Host "Starting $serviceName service..." -ForegroundColor Green
    try {
        Start-Service $serviceName
        Start-Sleep -Seconds 1

        if ((Get-Service $serviceName).Status -eq "Running") {
            Write-Host "$serviceName service started successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to start $serviceName service." -ForegroundColor Red
            return
        }
    } catch {
        Write-Host "Exception occurred while starting $serviceName. $_" -ForegroundColor Red
        return
    }
} else {
    Write-Host "$serviceName service is already running." -ForegroundColor Green
}

# 2: 自動加入 SSH key
if (-not (Test-Path $sshKeyPath)) {
    Write-Host "SSH key not found: $sshKeyPath" -ForegroundColor Red
    return
}

# 先檢查 key 是否已經在 agent 裡
$keyList = ssh-add -l 2>$null

if ($keyList -and $keyList -match (Split-Path $sshKeyPath -Leaf)) {
    Write-Host "SSH key already loaded in ssh-agent." -ForegroundColor Green
} else {
    Write-Host "Adding SSH key to ssh-agent: $sshKeyPath" -ForegroundColor Green
    try {
        ssh-add $sshKeyPath
        Write-Host "SSH key added successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to add SSH key: $_" -ForegroundColor Red
    }
}