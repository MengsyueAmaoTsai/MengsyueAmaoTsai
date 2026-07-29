#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# 用腳本所在路徑推導 repository 根目錄，不依賴目前工作目錄
$rootDirectory = Split-Path -Parent $PSScriptRoot

$profileContent = Get-Content -LiteralPath "$rootDirectory\src\PowerShell\Profiles\Default.ps1" -Raw

Set-Content -LiteralPath "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Value $profileContent -Force
Set-Content -LiteralPath "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1" -Value $profileContent -Force
