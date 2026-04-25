$ErrorActionPreference = 'Stop'

# 用腳本所在路徑，不依賴目前工作目錄
$rootDirectory = Split-Path -Parent $PSScriptRoot
$bootstrapperDirectory = Join-Path $rootDirectory "src\Bootstrappers\Windows"
$targetDirectory = "C:\Bootstrapper"

# ===== 需要系統管理員權限 =====
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run this script as Administrator."
}

# 刪除舊的 bootstrapper
if (Test-Path -Path $targetDirectory) {
    Remove-Item -Path $targetDirectory -Recurse -Force
    Write-Host "Old bootstrapper removed from $targetDirectory"
}

# 複製新的 bootstrapper
New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
Copy-Item -Path (Join-Path $bootstrapperDirectory '*') -Destination $targetDirectory -Recurse -Force

Write-Host "Bootstrapper installed to $targetDirectory"

# ===== 新增：Windows Task Scheduler 設定 =====
$taskName = "Bootstrapper"
$taskPath = "\MengsyueAmaoTsai\"
$entryScript = Join-Path $targetDirectory "Start-Bootstrapper.ps1"

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path $entryScript)) {
    throw "Entry script not found: $entryScript"
}

# 若舊任務存在，先移除，確保可重複安裝
$existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($null -ne $existing) {
    Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
    Write-Host "Old scheduled task removed: $taskPath$taskName"
}

# 建立 Task
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$entryScript`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

$principalTask = New-ScheduledTaskPrincipal `
    -UserId $currentUser `
    -LogonType Interactive `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName $taskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principalTask `
    -Description "Run bootstrapper at system startup." `
    -Force | Out-Null

Write-Host "Scheduled task created: $taskPath$taskName"