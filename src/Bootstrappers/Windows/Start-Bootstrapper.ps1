$ErrorActionPreference = 'Stop'

# =====================================================================================================================


# =====================================================================================================================
$sonarServiceName = "SonarQube"
$sonarService = Get-Service -Name $sonarServiceName -ErrorAction Silently

if ($null -ne $sonarService) {
    if ($sonarService.Status -ne 'Running') {
        Write-Host "Starting SonarQube service..." -ForegroundColor Green
        Start-Service -Name $sonarServiceName
        Write-Host "SonarQube service started." -ForegroundColor Green
    }
    else {
        Write-Host "SonarQube service is already running." -ForegroundColor Green
    }
}
else {
    Write-Host "SonarQube service not found." -ForegroundColor Yellow
}
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
    Start-Process "wt" 
}
else {
    Write-Host "Windows Terminal is not installed. Please install it from the Microsoft Store." -ForegroundColor Yellow
}