$rootDirectory = (Get-Location).Path

$settingsContent = Get-Content -Path "$rootDirectory\src\WindowsTerminal\default.json" -Raw

Set-Content -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value $settingsContent -Force
