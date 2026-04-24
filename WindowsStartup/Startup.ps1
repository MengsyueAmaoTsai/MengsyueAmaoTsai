# =====================================================================================================================
# Apply settings and configurations for Windows Terminal and PowerShell profile from the latest versions in the repository.
# =====================================================================================================================

# 1. Apply latest WindowsTerminal settings
$remoteTerminalSettingsUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/WindowsTerminal/settings.json'

try {
    $localTerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    Invoke-WebRequest -Uri $remoteTerminalSettingsUrl -OutFile $localTerminalSettingsPath
    Write-Host "Windows Terminal settings updated successfully."
}
catch {
    Write-Host "Failed to update Windows Terminal settings: $_"
}

# 2. Apply latest PowerShell profile
$remoteProfileUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/PowerShell/Profiles/Microsoft.PowerShell_profile.ps1'

try {
    $localProfilePath = "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
    Invoke-WebRequest -Uri $remoteProfileUrl -OutFile $localProfilePath
    Write-Host "PowerShell profile updated successfully."
}
catch {
    Write-Host "Failed to update PowerShell profile: $_"
}

# 3. Apply git configuration
git config --global user.name "Mengsyue Amao Tsai"
git config --global user.email "mengsyue.tsai@outlook.com"
git config --global user.signingkey "BB37B25BE7811D2AF2B9BB07EEB29E2560FA663C"
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
git config --global core.autocrlf true
git config --global core.editor "code --wait"
git config --global color.ui auto
git config --global commit.gpgsign true
git config --global gpg.program "C:\Program Files\GnuPG\bin\gpg.exe"

# =====================================================================================================================
# Ensure required services are running
# =====================================================================================================================
# 1. Ensure SonarQube Scanner service is running
$sonarServiceName = "SonarQube"
$sonarService = Get-Service -Name $sonarServiceName -ErrorAction SilentlyContinue

if ($null -ne $sonarService) {
    if ($sonarService.Status -ne 'Running') {
        Write-Host "Starting SonarQube service..."        
        Start-Service -Name $sonarServiceName
        Write-Host "SonarQube service started."
    }
    else {
        Write-Host "SonarQube service is already running."
    }
}
else {
    Write-Host "SonarQube service not found. Please ensure it is installed and configured correctly."
}