$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\Update-WindowsTerminalSettings.ps1"
. "$PSScriptRoot\Update-PowerShellProfile.ps1"

. "$PSScriptRoot\Ensure-Service-Gpg.ps1"
. "$PSScriptRoot\Ensure-Service-SshAgent.ps1"
. "$PSScriptRoot\Ensure-Service-SonarQube.ps1"
. "$PSScriptRoot\Ensure-Service-IIS.ps1"
. "$PSScriptRoot\Ensure-Service-AzAgent.ps1"

# =====================================================================================================================
Write-Host "Configure git global settings ..." -ForegroundColor Green

git config --global core.autocrlf true
git config --global core.editor "code --wait"
git config --global core.sshcommand "C:/Windows/System32/OpenSSH/ssh.exe"

git config --global user.name "Mengsyue Amao Tsai"
git config --global user.email "mengsyue.tsai@outlook.com"

git config --global commit.gpgsign true

git config --global color.ui auto

git config --global gpg.program "C:\Program Files\GnuPG\bin\gpg.exe"

Write-Host "Git global settings configured successfully." -ForegroundColor Green

# =====================================================================================================================

if (Get-Command "wt" -ErrorAction SilentlyContinue) {
    Read-Host "Press Enter to launch Windows Terminal with the new settings..."
    Start-Process "wt" 
}
else {
    Write-Host "Windows Terminal is not installed. Please install it from the Microsoft Store." -ForegroundColor Yellow
}