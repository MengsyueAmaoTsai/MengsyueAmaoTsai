#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# 用腳本所在路徑推導 repository 根目錄，不依賴目前工作目錄
$rootDirectory = Split-Path -Parent $PSScriptRoot

$settingsContent = Get-Content -LiteralPath "$rootDirectory\src\WindowsTerminal\default.json" -Raw

Set-Content -LiteralPath "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" -Value $settingsContent -Force
