$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\Bootstrapper.Output.ps1"

Write-BootstrapperBanner
Write-BootstrapperSection 'Settings'

& "$PSScriptRoot\Update-WindowsTerminalSettings.ps1"
& "$PSScriptRoot\Update-PowerShellProfile.ps1"
& "$PSScriptRoot\Update-OhMyPoshTheme.ps1"

Write-BootstrapperSection 'Services and agents'
. "$PSScriptRoot\Ensure-Service-Gpg.ps1"
. "$PSScriptRoot\Ensure-Service-SshAgent.ps1"
. "$PSScriptRoot\Ensure-Service-SonarQube.ps1"
. "$PSScriptRoot\Ensure-Service-IIS.ps1"
. "$PSScriptRoot\Ensure-Service-AzAgent.ps1"

Write-BootstrapperSection 'Git'

$gitSettings = @(
    @{ Name = 'core.autocrlf'; Value = 'true' }
    @{ Name = 'core.editor'; Value = 'code --wait' }
    @{ Name = 'core.sshcommand'; Value = 'C:/Windows/System32/OpenSSH/ssh.exe' }
    @{ Name = 'user.name'; Value = 'Mengsyue Amao Tsai' }
    @{ Name = 'user.email'; Value = 'mengsyue.tsai@outlook.com' }
    @{ Name = 'commit.gpgsign'; Value = 'true' }
    @{ Name = 'color.ui'; Value = 'auto' }
    @{ Name = 'gpg.program'; Value = 'C:\Program Files\GnuPG\bin\gpg.exe' }
)

foreach ($setting in $gitSettings) {
    & git config --global $setting.Name $setting.Value
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to configure Git setting '$($setting.Name)'. ExitCode=$LASTEXITCODE"
    }
}

Write-BootstrapperStatus -Level OK -Message 'Global settings configured'

# =====================================================================================================================
## Launch productivity applications (uncomment to enable)

# $executables = @(
#     "C:\Users\$env:USERNAME\AppData\Local\Discord\app-*\Discord.exe",
#     "C:\Users\$env:USERNAME\AppData\Local\LINE\bin\current\LINE.exe ",
#     "C:\Users\$env:USERNAME\AppData\Roaming\Telegram Desktop\Telegram.exe",
#     "C:\Program Files\WindowsApps\com.tinyspeck.slackdesktop_*_x64__8yrtsj140pw4g\app\Slack.exe",
#     "C:\Program Files\WindowsApps\Microsoft.OutlookForWindows_1.2026.420.300_x64__8wekyb3d8bbwe\olk.exe",
#     "C:\Program Files\WindowsApps\MSTeams_26032.214.4445.5584_x64__8wekyb3d8bbwe\ms-teams.exe"
# )

# foreach ($exe in $executables) {
#     $path = Get-ChildItem -Path $exe -ErrorAction SilentlyContinue | Select-Object -First 1
#     if ($path) {
#         Start-Process $path.FullName
#         Write-Host "Launched: $($path.FullName)" -ForegroundColor Green
#     }
#     else {
#         Write-Host "Executable not found: $exe" -ForegroundColor Yellow
#     }
# }

# =====================================================================================================================

Write-BootstrapperSection 'Complete'
Write-BootstrapperStatus -Level OK -Message 'Bootstrap completed successfully'
Write-BootstrapperStatus -Level INFO -Message 'Open a new terminal session to apply the updated profile and theme'

if (Get-Command 'wt' -ErrorAction SilentlyContinue) {
    $answer = Read-Host 'Launch Windows Terminal now? [y/N]'
    if ($answer -match '^(?i:y|yes)$') {
        Start-Process 'wt'
        Write-BootstrapperStatus -Level OK -Message 'Windows Terminal launched'
    }
    else {
        Write-BootstrapperStatus -Level SKIP -Message 'Windows Terminal launch skipped'
    }
}
else {
    Write-BootstrapperStatus -Level WARN -Message 'Windows Terminal is not installed'
}
