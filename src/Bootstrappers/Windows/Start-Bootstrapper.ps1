$ErrorActionPreference = 'Stop'

# 模組與本腳本同層，因此 repository 內與部署到 C:\Bootstrapper 之後都是同一條路徑。
Import-Module (Join-Path $PSScriptRoot 'MengsyueAmaoTsai.Bootstrap\MengsyueAmaoTsai.Bootstrap.psd1') -Force

$repositoryRawUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master'

# 遠端設定檔。新增一種設定只需在這裡加一筆，不必新增腳本。
$remoteConfigFiles = @(
    @{
        Description = 'Windows Terminal settings'
        Uri         = "$repositoryRawUrl/src/WindowsTerminal/default.json"
        Destination = @("$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json")
        Validate    = {
            param($Path)

            $settings = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($null -eq $settings.profiles) {
                throw 'The downloaded Windows Terminal settings do not contain a profiles section.'
            }
        }
    }
    @{
        Description = 'PowerShell profiles'
        Uri         = "$repositoryRawUrl/src/PowerShell/Profiles/Default.ps1"
        Destination = @(
            "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
        )
        Validate    = {
            param($Path)

            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$parseErrors) | Out-Null
            if ($parseErrors.Count -gt 0) {
                throw "The downloaded PowerShell profile is invalid: $($parseErrors[0].Message)"
            }
        }
    }
    @{
        Description = 'Oh My Posh theme'
        Uri         = "$repositoryRawUrl/src/OhMyPosh/Themes/default.omp.json"
        Destination = @("$env:USERPROFILE\Documents\PowerShell\default.omp.json")
        Validate    = {
            param($Path)

            $theme = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($null -eq $theme.blocks -or $theme.blocks.Count -eq 0) {
                throw 'The downloaded Oh My Posh theme does not contain any prompt blocks.'
            }
        }
    }
)

# 選用服務：存在就確保啟動，不存在則跳過。
$managedServices = @(
    @{ Name = 'SonarQube'; DisplayName = 'SonarQube' }
    @{ Name = 'W3SVC'; DisplayName = 'IIS' }
    @{ Name = 'vstsagent.richill-capital.Default.FUTURESAI-DEV-M'; DisplayName = 'Azure DevOps Agent' }
)

$gitSettings = [ordered]@{
    'core.autocrlf'  = 'true'
    'core.editor'    = 'code --wait'
    'core.sshcommand' = 'C:/Windows/System32/OpenSSH/ssh.exe'
    'user.name'      = 'Mengsyue Amao Tsai'
    'user.email'     = 'mengsyue.tsai@outlook.com'
    'commit.gpgsign' = 'true'
    'color.ui'       = 'auto'
    'gpg.program'    = 'C:\Program Files\GnuPG\bin\gpg.exe'
}

Write-BootstrapperBanner

Write-BootstrapperSection 'Settings'

foreach ($remoteConfigFile in $remoteConfigFiles) {
    Update-RemoteConfigFile @remoteConfigFile
}

Write-BootstrapperSection 'Services and agents'

Initialize-GpgAgent
Initialize-SshAgent

foreach ($managedService in $managedServices) {
    Start-ManagedService @managedService
}

Write-BootstrapperSection 'Git'

Set-GitGlobalConfiguration -Setting $gitSettings

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
