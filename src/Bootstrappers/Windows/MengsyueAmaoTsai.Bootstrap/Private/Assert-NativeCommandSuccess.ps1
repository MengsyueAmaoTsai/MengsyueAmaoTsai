<#
.SYNOPSIS
    原生命令的離開碼不為 0 時 throw。

.DESCRIPTION
    模組內多處呼叫 winget / gpgconf / ssh-add / git，原本各自重複
    `if ($LASTEXITCODE -ne 0) { throw ... }`。集中在這裡，錯誤訊息格式也一致。
#>
function Assert-NativeCommandSuccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Activity,

        [Parameter(Mandatory)]
        [int]$ExitCode
    )

    if ($ExitCode -ne 0) {
        throw "$Activity failed. ExitCode=$ExitCode"
    }
}
