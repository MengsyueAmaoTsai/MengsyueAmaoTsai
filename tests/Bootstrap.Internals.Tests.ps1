BeforeAll {
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Bootstrappers\Windows\MengsyueAmaoTsai.Bootstrap\MengsyueAmaoTsai.Bootstrap.psd1'
    Import-Module $manifestPath -Force
}

AfterAll {
    Remove-Module MengsyueAmaoTsai.Bootstrap -Force -ErrorAction SilentlyContinue
}

Describe 'Assert-NativeCommandSuccess' {

    It '離開碼為 0 時不 throw' {
        InModuleScope MengsyueAmaoTsai.Bootstrap {
            { Assert-NativeCommandSuccess -Activity 'winget install' -ExitCode 0 } | Should -Not -Throw
        }
    }

    It '離開碼非 0 時 throw 並帶出動作與離開碼' {
        InModuleScope MengsyueAmaoTsai.Bootstrap {
            { Assert-NativeCommandSuccess -Activity 'winget install' -ExitCode 3 } |
                Should -Throw '*winget install failed. ExitCode=3*'
        }
    }
}

Describe 'Set-GitGlobalConfiguration' {

    BeforeEach {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus { }
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap git { $global:LASTEXITCODE = 0 }
    }

    It '每個設定各呼叫一次 git config' {
        Set-GitGlobalConfiguration -Setting ([ordered]@{ 'color.ui' = 'auto'; 'core.autocrlf' = 'true' })

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap git -Times 2 -Exactly
    }

    It '以 --global 套用名稱與值' {
        Set-GitGlobalConfiguration -Setting ([ordered]@{ 'color.ui' = 'auto' })

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap git -Times 1 -Exactly `
            -ParameterFilter { $args -contains '--global' -and $args -contains 'color.ui' -and $args -contains 'auto' }
    }

    It 'git 回傳非 0 時 throw' {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap git { $global:LASTEXITCODE = 128 }

        { Set-GitGlobalConfiguration -Setting ([ordered]@{ 'color.ui' = 'auto' }) } |
            Should -Throw "*Configure Git setting 'color.ui' failed. ExitCode=128*"
    }

    It '-WhatIf 不呼叫 git' {
        Set-GitGlobalConfiguration -Setting ([ordered]@{ 'color.ui' = 'auto' }) -WhatIf

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap git -Times 0 -Exactly
    }
}

Describe 'Initialize-SshAgent 的提早結束路徑' {

    BeforeEach {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus { }
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service { }
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Set-Service { }
    }

    It '服務不存在時回報 SKIP' {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Get-Service { $null }

        Initialize-SshAgent -ServiceName 'absent-agent' -KeyPath 'C:\does\not\exist\id_rsa'

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'SKIP' }
        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service -Times 0 -Exactly
    }

    It '服務在執行但金鑰不存在時回報 WARN 並附上路徑' {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Get-Service { [pscustomobject]@{ Status = 'Running'; StartType = 'Manual' } }

        Initialize-SshAgent -ServiceName 'ssh-agent' -KeyPath 'C:\does\not\exist\id_rsa'

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'WARN' -and $Detail -contains 'C:\does\not\exist\id_rsa' }
    }
}
