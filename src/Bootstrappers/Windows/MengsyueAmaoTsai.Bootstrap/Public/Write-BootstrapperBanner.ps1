<#
.SYNOPSIS
    輸出 bootstrapper 的起始標題。
#>
function Write-BootstrapperBanner {
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-Host 'Windows workstation bootstrap' -ForegroundColor Cyan
    Write-Host '--------------------------------' -ForegroundColor DarkGray
}
