<#
.SYNOPSIS
    輸出單一步驟的執行結果。

.DESCRIPTION
    SKIP 表示選用元件未安裝，不視為錯誤；WARN 表示需要留意但流程可以繼續。
#>
function Write-BootstrapperStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('OK', 'INFO', 'SKIP', 'WARN', 'FAIL')]
        [string]$Level,

        [Parameter(Mandatory)]
        [string]$Message,

        [string[]]$Detail
    )

    $color = switch ($Level) {
        'OK' { 'Green' }
        'INFO' { 'Cyan' }
        'SKIP' { 'DarkGray' }
        'WARN' { 'Yellow' }
        'FAIL' { 'Red' }
    }

    Write-Host "  [$Level]" -NoNewline -ForegroundColor $color
    Write-Host " $Message"

    foreach ($line in $Detail) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-Host "         $line" -ForegroundColor DarkGray
        }
    }
}
