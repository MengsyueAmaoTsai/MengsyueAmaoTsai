. "$PSScriptRoot\Bootstrapper.Output.ps1"

$iisServiceName = "W3SVC"
$iisService = Get-Service -Name $iisServiceName -ErrorAction SilentlyContinue

if ($null -ne $iisService) {
    if ($iisService.Status -ne 'Running') {
        Write-BootstrapperStatus -Level INFO -Message 'Starting IIS'
        Start-Service -Name $iisServiceName
        Write-BootstrapperStatus -Level OK -Message 'IIS started'
    }
    else {
        Write-BootstrapperStatus -Level OK -Message 'IIS already running'
    }
}
else {
    Write-BootstrapperStatus -Level SKIP -Message 'IIS service not found'
}
