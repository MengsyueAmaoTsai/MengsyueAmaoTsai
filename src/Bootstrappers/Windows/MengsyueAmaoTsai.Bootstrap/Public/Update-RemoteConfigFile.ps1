<#
.SYNOPSIS
    下載遠端設定檔，驗證內容後才覆蓋本機目的地。

.DESCRIPTION
    Windows Terminal 設定、PowerShell profile 與 Oh My Posh theme 的更新流程完全相同 —
    下載到暫存檔、驗證、覆蓋目的地、清除暫存檔 — 只差來源 URL、目的地與驗證方式。
    驗證邏輯以 scriptblock 注入，新增一種設定檔只需在呼叫端多一筆資料。

.PARAMETER Validate
    接收暫存檔路徑的 scriptblock。內容不合法時應 throw；未提供則跳過驗證。
    驗證發生在覆蓋目的地之前，因此驗證失敗不會動到現有設定。

.EXAMPLE
    Update-RemoteConfigFile -Description 'Oh My Posh theme' `
        -Uri 'https://example.invalid/default.omp.json' `
        -Destination "$env:USERPROFILE\Documents\PowerShell\default.omp.json" `
        -Validate {
            param($Path)
            if (-not (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json).blocks) { throw 'No blocks.' }
        }
#>
function Update-RemoteConfigFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Description,

        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string[]]$Destination,

        [scriptblock]$Validate
    )

    # 暫存檔與目的地放同一個磁碟區，避免跨磁碟搬移
    $stagingDirectory = Split-Path -Parent $Destination[0]
    $temporaryPath = Join-Path $stagingDirectory ".bootstrapper.$([guid]::NewGuid().ToString('N')).tmp"

    # 一次性查詢參數，避開 raw.githubusercontent.com 的快取
    $separator = if ($Uri.Contains('?')) { '&' } else { '?' }
    $downloadUrl = "${Uri}${separator}bootstrapper=$([guid]::NewGuid().ToString('N'))"

    try {
        New-Item -ItemType Directory -Path $stagingDirectory -Force | Out-Null
        Invoke-WebRequest -Uri $downloadUrl -OutFile $temporaryPath -UseBasicParsing -Headers @{ 'Cache-Control' = 'no-cache' } -ErrorAction Stop

        if ($Validate) {
            & $Validate $temporaryPath
        }

        foreach ($path in $Destination) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null

            if ($PSCmdlet.ShouldProcess($path, "Update $Description")) {
                Copy-Item -LiteralPath $temporaryPath -Destination $path -Force
            }
        }

        $targets = if ($Destination.Count -gt 1) { " ($($Destination.Count) targets)" } else { '' }
        Write-BootstrapperStatus -Level OK -Message "$Description updated$targets"
    }
    catch {
        throw "Failed to update ${Description}: $($_.Exception.Message)"
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}
