param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

# 發生錯誤時立即中止；關閉進度列避免輸出過多資訊
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Release 資產下載網址（zip 與 sha256）
$Tag = "v$Version"
$ZipUrl = "https://github.com/MengsyueAmaoTsai/MengsyueAmaoTsai/releases/download/$Tag/windows-bootstrapper.zip"
$ShaUrl = "https://github.com/MengsyueAmaoTsai/MengsyueAmaoTsai/releases/download/$Tag/windows-bootstrapper.zip.sha256"

# 暫存路徑與目標安裝路徑
$tempRoot = Join-Path $env:TEMP "windows-bootstrapper-$Tag"
$zipPath = Join-Path $tempRoot "windows-bootstrapper.zip"
$shaPath = Join-Path $tempRoot "windows-bootstrapper.zip.sha256"
$targetPath = "C:\Bootstrapper"

# 1. 建立暫存資料夾
Write-Host "[1/5] Preparing temp folder: $tempRoot"
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

# 2. 下載壓縮檔
Write-Host "[2/5] Downloading zip..."
Invoke-WebRequest -Uri $ZipUrl -OutFile $zipPath

# 3. 下載 SHA256 檢查碼
Write-Host "[3/5] Downloading checksum..."
Invoke-WebRequest -Uri $ShaUrl -OutFile $shaPath

# 4. 驗證壓縮檔 SHA256 是否一致
Write-Host "[4/5] Verifying SHA256..."
$expected = (Get-Content -Path $shaPath -Raw).Trim().ToUpper()
$actual = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.Trim().ToUpper()

if ($expected -ne $actual) {
    throw "SHA256 mismatch. Expected=$expected, Actual=$actual"
}

# 5. 解壓縮到 C:\Bootstrapper（先清空既有內容）
Write-Host "[5/5] Extracting to $targetPath ..."
New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
Get-ChildItem -Path $targetPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive -Path $zipPath -DestinationPath $targetPath -Force

Write-Host "Done. Installed $Tag to $targetPath"