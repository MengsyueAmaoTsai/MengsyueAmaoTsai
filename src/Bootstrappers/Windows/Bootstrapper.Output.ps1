function Write-BootstrapperBanner {
    Write-Host ''
    Write-Host 'Windows workstation bootstrap' -ForegroundColor Cyan
    Write-Host '--------------------------------' -ForegroundColor DarkGray
}

function Write-BootstrapperSection {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-Host ''
    Write-Host ":: $Name" -ForegroundColor Cyan
}

function Write-BootstrapperStatus {
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
