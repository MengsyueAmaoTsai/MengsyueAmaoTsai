Set-StrictMode -Version Latest

# Private 先載入，Public 才能相依它們。
$privateFunctions = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private\*.ps1') -ErrorAction SilentlyContinue)
$publicFunctions = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public\*.ps1') -ErrorAction SilentlyContinue)

foreach ($file in ($privateFunctions + $publicFunctions)) {
    . $file.FullName
}

# 只匯出 Public 目錄下的函式；manifest 的 FunctionsToExport 再收斂一次。
Export-ModuleMember -Function $publicFunctions.BaseName
