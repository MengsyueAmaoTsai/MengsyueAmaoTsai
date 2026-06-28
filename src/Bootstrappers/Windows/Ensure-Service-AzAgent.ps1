. "$PSScriptRoot\Bootstrapper.Output.ps1"

$agentServiceName = "vstsagent.richill-capital.Default.FUTURESAI-DEV-MENGS"
$agentService = Get-Service -Name $agentServiceName -ErrorAction Silently

if ($null -ne $agentService) {
    if ($agentService.Status -ne 'Running') {
        Write-BootstrapperStatus -Level INFO -Message 'Starting Azure DevOps Agent'
        Start-Service -Name $agentServiceName
        Write-BootstrapperStatus -Level OK -Message 'Azure DevOps Agent started'
    }
    else {
        Write-BootstrapperStatus -Level OK -Message 'Azure DevOps Agent already running'
    }
}
else {
    Write-BootstrapperStatus -Level SKIP -Message 'Azure DevOps Agent service not found'
}
