. "$PSScriptRoot\Bootstrapper.Output.ps1"

<#
.SYNOPSIS
    服務存在就確保它在執行中，不存在則跳過。

.DESCRIPTION
    取代原本 Ensure-Service-IIS / Ensure-Service-SonarQube / Ensure-Service-AzAgent
    三支逐字複製的腳本 — 它們只差服務名稱與顯示名稱。新增一個受管服務改為在呼叫端
    的資料表加一筆，不再需要新增檔案。

    只處理「選用服務，有就啟動」這一種情境；Gpg 與 SshAgent 需要安裝、設定與金鑰載入，
    邏輯本質不同，因此維持獨立腳本。
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
