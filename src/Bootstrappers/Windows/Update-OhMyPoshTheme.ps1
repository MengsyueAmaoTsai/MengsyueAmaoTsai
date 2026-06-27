param(
    [string]$RemoteThemeUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/src/OhMyPosh/Themes/default.omp.json',
    [string]$DestinationPath = "$env:USERPROFILE\Documents\PowerShell\default.omp.json"
)

$destinationDirectory = Split-Path -Parent $DestinationPath
$temporaryPath = Join-Path $destinationDirectory ".theme.$([guid]::NewGuid().ToString('N')).json"
$separator = if ($RemoteThemeUrl.Contains('?')) { '&' } else { '?' }
$downloadUrl = "${RemoteThemeUrl}${separator}bootstrapper=$([guid]::NewGuid().ToString('N'))"

try {
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Invoke-WebRequest -Uri $downloadUrl -OutFile $temporaryPath -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -ErrorAction Stop

    $theme = Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json -ErrorAction Stop
    if ($null -eq $theme.blocks -or $theme.blocks.Count -eq 0) {
        throw 'The downloaded Oh My Posh theme does not contain any prompt blocks.'
    }

    Move-Item -LiteralPath $temporaryPath -Destination $DestinationPath -Force
    Write-Host "Oh My Posh theme updated: $DestinationPath" -ForegroundColor Green
}
catch {
    throw "Failed to update Oh My Posh theme: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
