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
# Import Modules 
# =====================================================================================================================
# 載入 PSReadLine
if ((Get-Module -ListAvailable -Name PSReadLine) -and $host.Name -eq 'ConsoleHost') { 
    Import-Module PSReadLine 
}  

# 設定 PSReadLine
if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) { 
}  

# 載入Terminal-Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) { 
    Import-Module Terminal-Icons 
}

# =====================================================================================================================
# Custom Functions
# =====================================================================================================================
function Write-Log {  
    param(  
        [Parameter(Mandatory)] [string]$Message,  
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'  
    )  

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')  

    $color = switch ($Level) {  
        'INFO'  { 'Green' }  
        'WARN'  { 'Yellow' }  
        'ERROR' { 'Red' }  
    }
    
    Write-Host "[$timestamp] [$Level] - $Message" -ForegroundColor $color
}  


# =====================================================================================================================
# Prompt Customization with oh-my-posh
# =====================================================================================================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $remoteThemeUrl = 'https://raw.githubusercontent.com/MengsyueAmaoTsai/MengsyueAmaoTsai/refs/heads/master/OhMyPosh/Themes/default.omp.json'
    $cachedTheme = Join-Path $PSScriptRoot 'default.remote.omp.json'
    $localTheme = Join-Path $PSScriptRoot 'default.omp.json'

    $themeToUse = $null

    try {
        Invoke-WebRequest -Uri $remoteThemeUrl -OutFile $cachedTheme -TimeoutSec 8
        $themeToUse = $cachedTheme
    } catch {
        Write-Log -Message "Failed to download remote theme: $remoteThemeUrl." -Level 'WARN'
    }

    if (-not $themeToUse -and (Test-Path $cachedTheme)) {
        $themeToUse = $cachedTheme
    } 
    
    if (-not $themeToUse -and (Test-Path $localTheme)) {
        $themeToUse = $localTheme
    }

    if (-not $themeToUse) {
        $fallbackTheme = Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\themes\jandedobbeleer.omp.json'
        if (Test-Path $fallbackTheme) {
            $themeToUse = $fallbackTheme
        } else {
            Write-Log -Message "Fallback theme not found: $fallbackTheme" -Level 'WARN'
        }
    }

    if ($themeToUse) {
        $env:POSH_THEME = $themeToUse
        oh-my-posh init pwsh --config $env:POSH_THEME | Invoke-Expression
    }    
} else {
    Write-Log -Message "oh-my-posh not found, skipping prompt customization." -Level 'WARN'
}
