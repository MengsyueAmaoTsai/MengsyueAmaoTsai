$ErrorActionPreference = 'Stop'

$logDirectory = 'C:\Startup\logs'
$logFile = Join-Path -Path $logDirectory -ChildPath 'Initialize.log'

if (-not (Test-Path -Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force 
}

Start-Transcript -Path $logFile -Append 

try {
    Write-Host "Start executing system initialization script."

    Write-Host "Complete system initialization script execution."
} catch {
    Write-Error $_
} finally {
    Stop-Transcript
}