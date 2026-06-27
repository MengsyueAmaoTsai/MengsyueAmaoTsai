param(
    [string]$RemoteSettingsUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/src/WindowsTerminal/default.json',
    [string]$DestinationPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
)

$destinationDirectory = Split-Path -Parent $DestinationPath
$temporaryPath = Join-Path $destinationDirectory ".settings.$([guid]::NewGuid().ToString('N')).json"
$separator = if ($RemoteSettingsUrl.Contains('?')) { '&' } else { '?' }
$downloadUrl = "${RemoteSettingsUrl}${separator}bootstrapper=$([guid]::NewGuid().ToString('N'))"

try {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Invoke-WebRequest -Uri $downloadUrl -OutFile $temporaryPath -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -ErrorAction Stop

    $settings = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $settings.profiles) {
        throw 'The downloaded Windows Terminal settings do not contain a profiles section.'
    }

    Move-Item -LiteralPath $temporaryPath -Destination $DestinationPath -Force
    Write-Host "Windows Terminal settings updated: $DestinationPath" -ForegroundColor Green
}
catch {
    throw "Failed to update Windows Terminal settings: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
