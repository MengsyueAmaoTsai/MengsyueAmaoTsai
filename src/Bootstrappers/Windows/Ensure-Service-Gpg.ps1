. "$PSScriptRoot\Bootstrapper.Output.ps1"

$gpgId = "GnuPG.Gpg4win"
$gpgCommand = Get-Command gpg.exe -ErrorAction SilentlyContinue

# 1. Ensure Gpg4win is installed
if ($gpgCommand) {
    Write-BootstrapperStatus -Level OK -Message 'Gpg4win installed'
}
else {
    Write-BootstrapperStatus -Level INFO -Message 'Installing Gpg4win'

    try {
        winget install --id $gpgId -e -h `
            --accept-source-agreements `
            --accept-package-agreements

        if ($LASTEXITCODE -ne 0) {
            throw "winget exited with code $LASTEXITCODE."
        }

        Write-BootstrapperStatus -Level OK -Message 'Gpg4win installed'
    }
    catch {
        throw "Failed to install Gpg4win: $($_.Exception.Message)"
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
$configurationChanged = $false

# 檢查是否已包含設定，避免覆蓋使用者自訂設定
if (-not (Test-Path $agentConf)) {
    $cacheSettings | Out-File -FilePath $agentConf -Encoding UTF8
    $configurationChanged = $true
}
else {
    $existing = Get-Content $agentConf
    foreach ($line in $cacheSettings) {
        if (-not ($existing -contains $line)) {
            Add-Content -Path $agentConf -Value $line
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

# 3: 啟動 / 重啟 gpg-agent
$gpgAgentProcess = Get-Process gpg-agent -ErrorAction SilentlyContinue

if ($gpgAgentProcess) {
    & gpgconf --kill gpg-agent
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stop GPG agent. ExitCode=$LASTEXITCODE"
    }
}

try {
    & gpgconf --launch gpg-agent
    if ($LASTEXITCODE -ne 0) {
        throw "gpgconf exited with code $LASTEXITCODE."
    }

    Start-Sleep -Seconds 1

    if (Get-Process gpg-agent -ErrorAction SilentlyContinue) {
        Write-BootstrapperStatus -Level OK -Message 'GPG agent running'
    }
    else {
        throw 'GPG agent did not start.'
    }
}
catch {
    throw "Failed to start GPG agent: $($_.Exception.Message)"
}
