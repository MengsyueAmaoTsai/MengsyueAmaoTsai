# Windows Bootstrapper 使用說明

`Start-Bootstrapper.ps1` 以遠端 GitHub repository 的 `master` branch 為唯一設定來源，下載並覆蓋本機的 Windows Terminal、PowerShell profile 與 Oh My Posh theme。

## 更新內容

| 設定 | 遠端來源 | 本機目的地 |
| --- | --- | --- |
| Windows Terminal | `src/WindowsTerminal/default.json` | `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| PowerShell profile | `src/PowerShell/Profiles/Default.ps1` | `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| VS Code PowerShell profile | `src/PowerShell/Profiles/Default.ps1` | `%USERPROFILE%\Documents\PowerShell\Microsoft.VSCode_profile.ps1` |
| Oh My Posh theme | `src/OhMyPosh/Themes/default.omp.json` | `%USERPROFILE%\Documents\PowerShell\default.omp.json` |

這些本機檔案會被直接覆蓋。下載內容會先寫入暫存檔，通過 JSON 或 PowerShell 語法驗證後才取代現有設定。

## 執行前準備

- 使用 Windows PowerShell 或 PowerShell 7。
- 確認電腦可以連線至 `raw.githubusercontent.com`。
- 安裝 Windows Terminal 與 Oh My Posh。
- 建議以系統管理員身分開啟 PowerShell，因為 bootstrapper 後續也會設定 Windows services。
- 確認要部署的變更已經 commit 並 push 到遠端 `master`。

Bootstrapper 下載的是遠端內容，不是目前 working tree。只有存在本機但尚未 push 的修改不會被部署。

## 正確使用流程

1. 修改 repository 內的來源設定：

   - `src/WindowsTerminal/default.json`
   - `src/PowerShell/Profiles/Default.ps1`
   - `src/OhMyPosh/Themes/default.omp.json`

2. Commit 並 push 到遠端 `master`：

   ```powershell
   git add src/WindowsTerminal/default.json `
       src/PowerShell/Profiles/Default.ps1 `
       src/OhMyPosh/Themes/default.omp.json
   git commit -m "Update Windows environment settings"
   git push origin master
   ```

3. 從 repository 根目錄執行 bootstrapper：

   ```powershell
   Set-Location C:\Users\mengs\source\repos\MengsyueAmaoTsai
   & .\src\Bootstrappers\Windows\Start-Bootstrapper.ps1
   ```

4. 等待下列三項成功訊息：

   ```text
   Windows Terminal settings updated: ...
   PowerShell profile updated: ...
   Oh My Posh theme updated: ...
   ```

5. 關閉目前的 Windows Terminal 或 VS Code terminal，重新開啟新的 terminal session。

PowerShell profile 只會在新的 session 啟動時載入，因此執行 bootstrapper 的既有 prompt 不一定會立即改變。

## 驗證安裝結果

確認三個主要目的檔案存在：

```powershell
$terminalSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$powerShellProfile = "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$ohMyPoshTheme = "$env:USERPROFILE\Documents\PowerShell\default.omp.json"

Test-Path $terminalSettings
Test-Path $powerShellProfile
Test-Path $ohMyPoshTheme
```

在新的 PowerShell session 確認實際載入的 theme：

```powershell
$env:POSH_THEME
oh-my-posh debug --config "$env:USERPROFILE\Documents\PowerShell\default.omp.json" --plain
```

`$env:POSH_THEME` 應指向：

```text
C:\Users\<使用者名稱>\Documents\PowerShell\default.omp.json
```

## 常見問題

### 修改後仍然下載舊內容

先確認變更已 push 到遠端 `master`，而不只是完成本機 commit：

```powershell
git status -sb
git log -1 --oneline
git ls-remote origin refs/heads/master
```

本機 `HEAD` 與遠端 `master` 應指向相同 commit。

### Theme 檔案已更新，但畫面沒有改變

完全關閉並重新開啟 Windows Terminal。VS Code 則關閉現有 integrated terminal，或執行 `Developer: Reload Window`。

接著確認 `$env:POSH_THEME` 指向 `default.omp.json`，並使用 `oh-my-posh debug` 檢查 render 結果。

### Bootstrapper 執行到一半停止

Bootstrapper 使用停止於錯誤的執行模式。任何下載、驗證、檔案寫入或 Windows service 設定失敗時，後續步驟都不會繼續。請處理畫面上顯示的第一個錯誤後重新執行。

### PowerShell 阻擋 script 執行

可以在不修改永久 execution policy 的情況下執行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\src\Bootstrappers\Windows\Start-Bootstrapper.ps1
```

## 安全說明

Bootstrapper 會覆蓋本機設定，而且下載的 PowerShell profile 會在之後的 terminal session 執行。執行前應確認 repository、branch 與最新 commit 都是可信任的內容。
