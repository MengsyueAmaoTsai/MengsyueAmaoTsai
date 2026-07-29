<#
.SYNOPSIS
    套用一組 global Git 設定。

.PARAMETER Setting
    設定名稱對應值的字典。建議用 [ordered] 保留套用順序，便於閱讀輸出。

.EXAMPLE
    Set-GitGlobalConfiguration -Setting ([ordered]@{ 'color.ui' = 'auto' })
#>
function Set-GitGlobalConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Setting
    )

    foreach ($name in @($Setting.Keys)) {
        if (-not $PSCmdlet.ShouldProcess($name, 'Set global Git configuration')) {
            continue
        }

        & git config --global $name $Setting[$name]
        Assert-NativeCommandSuccess -Activity "Configure Git setting '$name'" -ExitCode $LASTEXITCODE
    }

    Write-BootstrapperStatus -Level OK -Message 'Global settings configured'
}
