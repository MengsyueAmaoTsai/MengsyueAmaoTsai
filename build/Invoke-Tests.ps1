#Requires -Modules Pester

<#
.SYNOPSIS
    執行 tests\ 底下的 Pester 測試，輸出 NUnit 格式結果供 CI 收集。
#>
[CmdletBinding()]
param(
    [string]$Path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'),

    [string]$ResultPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'artifacts\testResults.xml')
)

$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path (Split-Path -Parent $ResultPath) -Force | Out-Null

$configuration = New-PesterConfiguration
$configuration.Run.Path = $Path
$configuration.Run.Throw = $true
$configuration.Output.Verbosity = 'Detailed'
$configuration.TestResult.Enabled = $true
$configuration.TestResult.OutputPath = $ResultPath

Invoke-Pester -Configuration $configuration
