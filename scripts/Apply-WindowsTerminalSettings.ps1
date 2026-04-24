$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script as Administrator."
}

$rootDirectory = (Get-Location).Path

$settingsContent = Get-Content -Path "$rootDirectory\src\WindowsTerminal\default.json" -Raw

Set-Content -Path "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value $settingsContent -Force
