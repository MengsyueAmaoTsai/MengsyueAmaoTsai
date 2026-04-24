# 1 | 開發環境啟動設定

# | 套用預設 WindowsTerminal 設定檔
# $remoteTerminalSettingsUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/WindowsTerminal/settings.json'

try {
    $localTerminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\default.json"
    Invoke-WebRequest -Uri $remoteTerminalSettingsUrl -OutFile $localTerminalSettingsPath
    Write-Host "Windows Terminal settings updated successfully."
}
catch {
    Write-Host "Failed to update Windows Terminal settings: $_"
}

# | 套用預設 PowerShell 配置檔
$remoteProfileUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/PowerShell/Profiles/Default.ps1'

try {
    $rawContent = Invoke-WebRequest -Uri $remoteProfileUrl -UseBasicParsing
    $rawContent.Content | Out-File -FilePath "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Encoding UTF8 -Force
    $rawContent.Content | Out-File -FilePath "$HOME\Documents\PowerShell\Microsoft.VSCode_profile.ps1" -Encoding UTF8 -Force
    
    Write-Host "PowerShell profile updated successfully."
}
catch {
    Write-Host "Failed to update PowerShell profile: $_"
}

# | 配置 Git 全局設定
git config --global user.name "Mengsyue Amao Tsai"
git config --global user.email "mengsyue.tsai@outlook.com"
git config --global user.signingkey "BB37B25BE7811D2AF2B9BB07EEB29E2560FA663C"
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
git config --global core.autocrlf true
git config --global core.editor "code --wait"
git config --global color.ui auto
git config --global commit.gpgsign true
git config --global gpg.program "C:\Program Files\GnuPG\bin\gpg.exe"


# 1-2 | 啟動開發相關服務
# | 確保 SonarQube 服務正在運行
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