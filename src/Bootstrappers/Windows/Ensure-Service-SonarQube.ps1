. "$PSScriptRoot\Bootstrapper.Output.ps1"

$sonarServiceName = "SonarQube"
$sonarService = Get-Service -Name $sonarServiceName -ErrorAction SilentlyContinue

if ($null -ne $sonarService) {
    if ($sonarService.Status -ne 'Running') {
        Write-BootstrapperStatus -Level INFO -Message 'Starting SonarQube'
        Start-Service -Name $sonarServiceName
        Write-BootstrapperStatus -Level OK -Message 'SonarQube started'
    }
    else {
        Write-BootstrapperStatus -Level OK -Message 'SonarQube already running'
    }
}
else {
    Write-BootstrapperStatus -Level SKIP -Message 'SonarQube service not found'
}
