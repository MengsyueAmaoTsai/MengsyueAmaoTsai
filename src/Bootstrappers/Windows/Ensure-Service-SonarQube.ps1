$sonarServiceName = "SonarQube"
$sonarService = Get-Service -Name $sonarServiceName -ErrorAction Silently

if ($null -ne $sonarService) {
    if ($sonarService.Status -ne 'Running') {
        Write-Host "Starting SonarQube service..." -ForegroundColor Green
        Start-Service -Name $sonarServiceName
        Write-Host "SonarQube service started." -ForegroundColor Green
    }
    else {
        Write-Host "SonarQube service is already running." -ForegroundColor Green
    }
}
else {
    Write-Host "SonarQube service not found." -ForegroundColor Yellow
}