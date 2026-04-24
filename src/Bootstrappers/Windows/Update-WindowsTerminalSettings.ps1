$remoteSettingsUrl = "https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/src/WindowsTerminal/default.json"

try {
    $settingsContent = Invoke-WebRequest -Uri $remoteSettingsUrl -UseBasicParsing -ErrorAction Stop
    Set-Content -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value $settingsContent.Content -Force
    Write-Host "Windows Terminal settings have been updated successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to update Windows Terminal settings: $_"
}