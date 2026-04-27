# Scripts 說明文件

本資料夾放的是「Windows 開發環境初始化 / 套用個人化設定」相關腳本。  
主要目標是：快速重建同一套終端機與 PowerShell 工作環境。

---

## 腳本總覽

| 腳本 | 主要用途 | 典型執行時機 |
|---|---|---|
| `Install-Bootstrapper.ps1` | 安裝或準備基礎工具（bootstrapping） | 新電腦、重灌後第一步 |
| `Apply-PowerShellProfile.ps1` | 套用 PowerShell 個人設定（Profile） | Bootstrap 後、想同步 shell 體驗時 |
| `Apply-WindowsTerminalSettings.ps1` | 套用 Windows Terminal 設定 | Bootstrap 後、想同步終端機 UI/快捷鍵時 |

---

## 1) `Install-Bootstrapper.ps1`

### 用途
建立「可用的基礎環境」，通常包含：
- 安裝必要套件管理工具（例如 winget/choco/scoop，依腳本實作為準）
- 安裝常用 CLI 工具或執行環境（Git、PowerShell 模組、語言 SDK 等）
- 建立後續腳本需要的前置條件

### 你會在什麼情境使用
- 新機第一次設定
- 重灌後快速回復開發環境
- 想讓多台機器維持同一套工具版本基線

### 可能影響
- 會下載與安裝系統層級軟體
- 可能需要系統管理員權限
- 可能變更 PATH 或系統設定（視腳本內容）

---

## 2) `Apply-PowerShellProfile.ps1`

### 用途
把 PowerShell 的個人化設定套到目前使用者環境，常見包含：
- `Microsoft.PowerShell_profile.ps1` 內容更新
- alias、function、prompt 主題、PSReadLine 設定
- 常用模組自動匯入或安裝檢查

### 你會在什麼情境使用
- 想同步同一套命令列體驗（別名、提示字元、快捷鍵）
- 新機完成 bootstrap 後，開始調整 shell 使用習慣
- profile 被覆蓋或遺失時重新套用

### 可能影響
- 啟動 PowerShell 的行為會改變（prompt、顏色、補全規則等）
- 若有舊 profile，可能被覆寫或合併（依腳本實作）

---

## 3) `Apply-WindowsTerminalSettings.ps1`

### 用途
把 Windows Terminal 設定標準化，常見包含：
- `settings.json` 佈景主題、字型、配色、透明度
- 預設 shell、啟動行為、分頁設定
- 快捷鍵（keybindings）與 profile 參數

### 你會在什麼情境使用
- 想讓不同電腦有一致的 Terminal UI/UX
- 新安裝 Windows Terminal 後快速還原偏好設定
- 設定檔損壞或被重置後重新套用

### 可能影響
- 會直接影響 Windows Terminal 顯示與操作方式
- 若直接覆寫 `settings.json`，使用者手動調整可能被取代

---

## 建議執行順序

1. `Install-Bootstrapper.ps1`  
2. `Apply-PowerShellProfile.ps1`  
3. `Apply-WindowsTerminalSettings.ps1`  

> 原因：先準備工具，再套 shell 設定，最後套終端機外觀與快捷鍵。

---

## 執行方式（PowerShell）

在 `scripts` 資料夾中執行：

```powershell
# 需要時先允許目前工作階段執行本機腳本
Set-ExecutionPolicy -Scope Process Bypass -Force

.\Install-Bootstrapper.ps1
.\Apply-PowerShellProfile.ps1
.\Apply-WindowsTerminalSettings.ps1
```

---

## 驗證建議

- **Bootstrap 完成後**：確認常用指令可用（如 `git --version`）
- **Profile 套用後**：重開 PowerShell，確認 prompt / alias 生效
- **Terminal 套用後**：重開 Windows Terminal，確認主題與快捷鍵生效

---

## 失敗排查

- 以系統管理員身分啟動 PowerShell 再執行一次
- 檢查網路與代理設定（安裝套件常受影響）
- 檢查執行政策：
  ```powershell
  Get-ExecutionPolicy -List
  ```
- 若有覆寫風險，先備份既有設定檔（Profile、Windows Terminal `settings.json`）

---

