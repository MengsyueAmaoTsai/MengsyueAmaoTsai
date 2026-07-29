#Requires -Modules PSScriptAnalyzer

<#
.SYNOPSIS
    對整個 repository 執行 PSScriptAnalyzer，有任何 finding 就讓流程失敗。

.DESCRIPTION
    CI 與本機執行同一支腳本，避免「本機過了但 CI 掛掉」。
    規則的例外集中在 repository 根目錄的 PSScriptAnalyzerSettings.psd1。
#>
[CmdletBinding()]
param(
    [string]$Path = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$settingsPath = Join-Path $Path 'PSScriptAnalyzerSettings.psd1'
$findings = @(Invoke-ScriptAnalyzer -Path $Path -Recurse -Settings $settingsPath)

if ($findings.Count -eq 0) {
    Write-Host 'PSScriptAnalyzer: 0 findings.' -ForegroundColor Green
    return
}

$findings |
    Sort-Object Severity, ScriptName, Line |
    Format-Table -AutoSize -Wrap -Property Severity, ScriptName, Line, RuleName, Message |
    Out-String -Width 200 |
    Write-Host

throw "PSScriptAnalyzer reported $($findings.Count) finding(s)."
