@{
    Severity     = @('Error', 'Warning', 'Information')

    ExcludeRules = @(
        # 這個 repository 的產出就是主控台工具。bootstrapper 的進度輸出與 profile 的
        # 提示訊息是要給人看的使用者介面，不是要送進 pipeline 的資料，Write-Host 是
        # 正確選擇 —— 改用 Write-Output 反而會污染函式的回傳值。
        'PSAvoidUsingWriteHost'

        # oh-my-posh 官方指定的初始化方式就是
        # `oh-my-posh init pwsh --config <theme> | Invoke-Expression`。
        # 輸入來自本機安裝的執行檔，不是外部或使用者輸入。
        'PSAvoidUsingInvokeExpression'
    )
}
