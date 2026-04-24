$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script as Administrator."
}

$rootDirectory = (Get-Location).Path

$profileContent = Get-Content -Path "$rootDirectory\src\PowerShell\Profiles\Default.ps1" -Raw

Set-Content -Path "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Value $profileContent -Force
Set-Content -Path "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1" -Value $profileContent -Force