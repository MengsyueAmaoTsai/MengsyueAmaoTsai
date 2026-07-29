<#
.SYNOPSIS
    服務存在就確保它在執行中，不存在則跳過。

.DESCRIPTION
    只處理「選用服務，有就啟動」這一種情境。Gpg 與 SshAgent 需要安裝、設定與金鑰載入，
    邏輯本質不同，因此各自有獨立的函式。
#>
function Start-ManagedService {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$DisplayName
    )

    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        Write-BootstrapperStatus -Level SKIP -Message "$DisplayName service not found"
        return
    }

    if ($service.Status -eq 'Running') {
        Write-BootstrapperStatus -Level OK -Message "$DisplayName already running"
        return
    }

    Write-BootstrapperStatus -Level INFO -Message "Starting $DisplayName"

    if ($PSCmdlet.ShouldProcess($Name, 'Start service')) {
        Start-Service -Name $Name
        Write-BootstrapperStatus -Level OK -Message "$DisplayName started"
    }
}
