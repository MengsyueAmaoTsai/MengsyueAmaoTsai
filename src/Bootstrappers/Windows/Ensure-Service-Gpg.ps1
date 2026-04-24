$gpgId = "GnuPG.Gpg4win"
$gpgCommand = Get-Command gpg.exe -ErrorAction SilentlyContinue

# 1. Ensure Gpg4win is installed
if ($gpgCommand) {
    Write-Host "Gpg4win already installed at: $($gpgCommand.Path)" -ForegroundColor Green
} else {
    Write-Host "$gpgId is not installed. Start installation..." -ForegroundColor Yellow

    try {
        winget install --id $gpgId -e -h `
            --accept-source-agreements `
            --accept-package-agreements

        if ($LASTEXITCODE -ne 0) {
            Write-Host "$gpgId installation failed. ExitCode=$LASTEXITCODE" -ForegroundColor Red
            return
        }

        Write-Host "$gpgId installation completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Exception occurred while installing $gpgId : $_" -ForegroundColor Red
        return
    }
}

# 2. Set gpg-agent cache TTL
$gnupgDir = Join-Path $env:APPDATA "gnupg"

if (-not (Test-Path $gnupgDir)) {
    New-Item -Path $gnupgDir -ItemType Directory | Out-Null
}

$agentConf = Join-Path $gnupgDir "gpg-agent.conf"
$cacheSettings = @(
    "default-cache-ttl 86400"   # 1 day
    "max-cache-ttl 604800"      # 7 days
)

# 檢查是否已包含設定，避免覆蓋使用者自訂設定
if (-not (Test-Path $agentConf)) {
    Write-Host "Creating gpg-agent.conf with cache settings." -ForegroundColor Green
    $cacheSettings | Out-File -FilePath $agentConf -Encoding UTF8
} else {
    $existing = Get-Content $agentConf
    foreach ($line in $cacheSettings) {
        if (-not ($existing -contains $line)) {
            Write-Host "Adding missing cache setting: $line" -ForegroundColor Green
            Add-Content -Path $agentConf -Value $line
        }
    }
}


# 3: 啟動 / 重啟 gpg-agent
$gpgAgentProcess = Get-Process gpg-agent -ErrorAction SilentlyContinue

if ($gpgAgentProcess) {
    Write-Host "gpg-agent is already running. Restarting to apply cache settings..." -ForegroundColor Green
    & gpgconf --kill gpg-agent
}

Write-Host "Launching gpg-agent..." -ForegroundColor Green
try {
    & gpgconf --launch gpg-agent
    Start-Sleep -Seconds 1

    if (Get-Process gpg-agent -ErrorAction SilentlyContinue) {
        Write-Host "gpg-agent started successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to start gpg-agent." -ForegroundColor Red
    }
}
catch {
    Write-Host "Exception occurred while starting gpg-agent: $_" -ForegroundColor Red
}