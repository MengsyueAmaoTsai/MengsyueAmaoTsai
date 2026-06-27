param(
    [string]$RemoteProfileUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/src/PowerShell/Profiles/Default.ps1',
    [string[]]$DestinationPaths = @(
        "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
        "$env:USERPROFILE\Documents\PowerShell\Microsoft.VSCode_profile.ps1"
    )
)

$profileDirectory = Split-Path -Parent $DestinationPaths[0]
$temporaryPath = Join-Path $profileDirectory ".profile.$([guid]::NewGuid().ToString('N')).ps1"
$separator = if ($RemoteProfileUrl.Contains('?')) { '&' } else { '?' }
$downloadUrl = "${RemoteProfileUrl}${separator}bootstrapper=$([guid]::NewGuid().ToString('N'))"

try {
    New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    Invoke-WebRequest -Uri $downloadUrl -OutFile $temporaryPath -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -ErrorAction Stop

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $temporaryPath,
        [ref]$tokens,
        [ref]$parseErrors
    ) | Out-Null

    if ($parseErrors.Count -gt 0) {
        throw "The downloaded PowerShell profile is invalid: $($parseErrors[0].Message)"
    }

    foreach ($destinationPath in $DestinationPaths) {
        $destinationDirectory = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        Copy-Item -LiteralPath $temporaryPath -Destination $destinationPath -Force
        Write-Host "PowerShell profile updated: $destinationPath" -ForegroundColor Green
    }
}
catch {
    throw "Failed to update PowerShell profiles: $($_.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}
