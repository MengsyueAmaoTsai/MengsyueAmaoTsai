$iisServiceName = "W3SVC"
$iisService = Get-Service -Name $iisServiceName -ErrorAction Silently

if ($null -ne $iisService) {
    if ($iisService.Status -ne 'Running') {
        Write-Host "Starting IIS service..." -ForegroundColor Green
        Start-Service -Name $iisServiceName
        Write-Host "IIS service started." -ForegroundColor Green
    }
    else {
        Write-Host "IIS service is already running." -ForegroundColor Green
    }
}
else {
    Write-Host "IIS service not found." -ForegroundColor Yellow
}