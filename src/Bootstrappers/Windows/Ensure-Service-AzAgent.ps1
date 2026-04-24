$agentServiceName = "vstsagent.richill-capital.Default.FUTURESAI-DEV-MENGS"
$agentService = Get-Service -Name $agentServiceName -ErrorAction Silently

if ($null -ne $agentService) {
    if ($agentService.Status -ne 'Running') {
        Write-Host "Starting Azure DevOps Agent service..." -ForegroundColor Green
        Start-Service -Name $agentServiceName
        Write-Host "Azure DevOps Agent service started." -ForegroundColor Green
    }
    else {
        Write-Host "Azure DevOps Agent service is already running." -ForegroundColor Green
    }
}
else {
    Write-Host "Azure DevOps Agent service not found." -ForegroundColor Yellow
}