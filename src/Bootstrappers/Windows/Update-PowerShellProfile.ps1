$remoteProfileUrl = "https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/src/PowerShell/Profiles/Default.ps1"

try {
    $profileContent = Invoke-WebRequest -Uri $remoteProfileUrl -UseBasicParsing -ErrorAction Stop
    Set-Content -Path "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Value $profileContent.Content -Force
    Set-Content -Path "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1" -Value $profileContent.Content -Force
    Write-Host "PowerShell profiles have been updated successfully."
}
catch {
    Write-Error "Failed to update PowerShell profiles: $_"
}