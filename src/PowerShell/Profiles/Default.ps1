Set-StrictMode -Version Latest # 啟用最嚴格語法/變數檢查，避免因拼字或未初始化變數造成交易腳本誤判
$ErrorActionPreference = 'Stop'  # 將非終止錯誤改為終止錯誤，確保流程在異常時立即停止
# =====================================================================================================================
# Global Setup
# =====================================================================================================================
$PSNativeCommandUseErrorActionPreference = $true  # 讓原生命令也遵守 Stop 行為，避免外部工具失敗卻被忽略

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()  # 強制主控台 UTF-8，避免中文/符號亂碼導致日誌難以追查
$OutputEncoding = [System.Text.UTF8Encoding]::new()  # 統一管線輸出編碼，降低跨工具資料交換失真

$env:TZ = 'UTC'  # 統一時區為 UTC

$PSStyle.OutputRendering = 'Host'  # 固定輸出渲染行為，減少不同終端造成的可讀性差異
$MaximumHistoryCount = 5000  # 限制指令歷史數量，兼顧追溯需求與本機資料暴露風險

# =====================================================================================================================
# 環境變數 PATH 設定
# =====================================================================================================================
function Add-PathEntry {
    param(
        [Parameter(Mandatory)] [string]$Directory
    )

    if (-not (Test-Path -LiteralPath $Directory)) {
        return
    }

    $normalized = $Directory.TrimEnd('\')
    $isPresent = $env:PATH -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -ieq $normalized }

    if ($isPresent) {
        return
    }

    $env:PATH += ";$Directory"
}

# MSBuild：已可從 PATH 解析（例如已寫入 user 環境變數）就不必再呼叫 vswhere。
if (-not (Get-Command MSBuild.exe -ErrorAction SilentlyContinue)) {
    $vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $vswherePath) {
        $msbuildPath = & $vswherePath -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1

        if ($msbuildPath) {
            Add-PathEntry -Directory ($msbuildPath | Split-Path -Parent)
        }
    }
}

# tlbimp：遞迴掃描整個 Windows SDK 目錄很慢，已可從 PATH 解析就直接跳過掃描。
if (-not (Get-Command tlbimp.exe -ErrorAction SilentlyContinue)) {
    $windowsSdkPath = "${env:ProgramFiles(x86)}\Microsoft SDKs\Windows"

    if (Test-Path $windowsSdkPath) {
        $tlbimpPath = Get-ChildItem -Path $windowsSdkPath -Recurse -Filter "tlbimp.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($tlbimpPath) {
            Add-PathEntry -Directory $tlbimpPath.DirectoryName
        }
    }
}

# cTrader CLI：安裝在 %LOCALAPPDATA%\Programs\cTrader CLI，目錄名固定，直接加入 PATH。
if (-not (Get-Command ctrader-cli.exe -ErrorAction SilentlyContinue)) {
    Add-PathEntry -Directory (Join-Path $env:LOCALAPPDATA 'Programs\cTrader CLI')
}

# Nodepad++ CLI：安裝在 %ProgramFiles%\Notepad++，目錄名固定，直接加入 PATH。
if (-not (Get-Command npp.exe -ErrorAction SilentlyContinue)) {
    Add-PathEntry -Directory (Join-Path $env:ProgramFiles 'Notepad++')
}

# =====================================================================================================================
# Import Modules
# =====================================================================================================================
# 載入 PSReadLine
if ((Get-Module -ListAvailable -Name PSReadLine) -and $host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
}

# 設定 PSReadLine
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
}

function Reset-TerminalIconsUserCache {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $basePath = $env:APPDATA
    if (-not $basePath) {
        $basePath = [Environment]::GetFolderPath('ApplicationData')
    }

    if (-not $basePath) {
        return $null
    }

    $cachePath = [IO.Path]::Combine($basePath, 'powershell', 'Community', 'Terminal-Icons')
    if (-not (Test-Path -LiteralPath $cachePath)) {
        return $null
    }

    $parentPath = Split-Path -Parent $cachePath
    $backupPath = Join-Path $parentPath "Terminal-Icons.corrupt-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))-$PID"

    if (-not $PSCmdlet.ShouldProcess($cachePath, 'Move corrupt Terminal-Icons cache aside')) {
        return $null
    }

    Move-Item -LiteralPath $cachePath -Destination $backupPath -Force
    $backupPath
}

function Import-TerminalIconsSafely {
    $mutex = [Threading.Mutex]::new($false, 'Local\MengsyueAmaoTsai.TerminalIconsCache')
    $lockTaken = $false

    try {
        try {
            $lockTaken = $mutex.WaitOne(15000)
        }
        catch [Threading.AbandonedMutexException] {
            $lockTaken = $true
        }

        if (-not $lockTaken) {
            Write-Warning 'Timed out waiting to import Terminal-Icons.'
            return
        }

        try {
            Import-Module Terminal-Icons -ErrorAction Stop
        }
        catch {
            $importError = $_
            $isCacheCorruption = (
                $importError.Exception -is [System.Xml.XmlException] -or
                $importError.FullyQualifiedErrorId -match 'Import-?CliXml' -or
                $importError.Exception.Message -match 'XmlNodeType|dictionary entry|XML|parse|element'
            )

            if (-not $isCacheCorruption) {
                Write-Warning "Failed to import Terminal-Icons: $($importError.Exception.Message)"
                return
            }

            try {
                Remove-Module Terminal-Icons -Force -ErrorAction SilentlyContinue
                Reset-TerminalIconsUserCache | Out-Null
                Import-Module Terminal-Icons -ErrorAction Stop
            }
            catch {
                Write-Warning "Failed to import Terminal-Icons after rebuilding cache: $($_.Exception.Message)"
            }
        }
    }
    finally {
        if ($lockTaken) {
            $mutex.ReleaseMutex()
        }

        $mutex.Dispose()
    }
}

# Terminal-Icons 會在匯入時重寫共用的 CLIXML 快取；序列化匯入以避免多個終端同時寫壞檔案。
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-TerminalIconsSafely
}

# 載入 WebAdminstration
if (Get-Module -ListAvailable -Name WebAdministration) {
    Import-Module WebAdministration
}

# =====================================================================================================================
# Prompt Customization with oh-my-posh
# =====================================================================================================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $localTheme = Join-Path $PSScriptRoot 'default.omp.json'

    $themeToUse = $null

    if (Test-Path $localTheme) {
        $themeToUse = $localTheme
    }

    if (-not $themeToUse) {
        $fallbackTheme = Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\themes\jandedobbeleer.omp.json'
        if (Test-Path $fallbackTheme) {
            $themeToUse = $fallbackTheme
        } else {
            Write-Warning "Fallback theme not found: $fallbackTheme"
        }
    }

    if ($themeToUse) {
        $env:POSH_THEME = $themeToUse
        oh-my-posh init pwsh --config $env:POSH_THEME | Invoke-Expression
    }
} else {
    Write-Warning 'oh-my-posh not found, skipping prompt customization.'
}

