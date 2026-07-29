<#
.SYNOPSIS
    輸出 bootstrapper 的區段標題。
#>
function Write-BootstrapperSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-Host ''
    Write-Host ":: $Name" -ForegroundColor Cyan
}
