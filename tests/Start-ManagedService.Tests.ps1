BeforeAll {
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Bootstrappers\Windows\MengsyueAmaoTsai.Bootstrap\MengsyueAmaoTsai.Bootstrap.psd1'
    Import-Module $manifestPath -Force
}

AfterAll {
    Remove-Module MengsyueAmaoTsai.Bootstrap -Force -ErrorAction SilentlyContinue
}

Describe 'Start-ManagedService' {

    BeforeEach {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus { }
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service { }
    }

    Context '服務不存在' {

        BeforeEach {
            Mock -ModuleName MengsyueAmaoTsai.Bootstrap Get-Service { $null }
        }

        It '回報 SKIP' {
            Start-ManagedService -Name 'Absent' -DisplayName 'Absent Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
                -ParameterFilter { $Level -eq 'SKIP' -and $Message -eq 'Absent Service service not found' }
        }

        It '不嘗試啟動服務' {
            Start-ManagedService -Name 'Absent' -DisplayName 'Absent Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service -Times 0 -Exactly
        }
    }

    Context '服務已在執行' {

        BeforeEach {
            Mock -ModuleName MengsyueAmaoTsai.Bootstrap Get-Service { [pscustomobject]@{ Name = 'Present'; Status = 'Running' } }
        }

        It '回報已在執行' {
            Start-ManagedService -Name 'Present' -DisplayName 'Present Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
                -ParameterFilter { $Level -eq 'OK' -and $Message -eq 'Present Service already running' }
        }

        It '不重複啟動' {
            Start-ManagedService -Name 'Present' -DisplayName 'Present Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service -Times 0 -Exactly
        }
    }

    Context '服務已停止' {

        BeforeEach {
            Mock -ModuleName MengsyueAmaoTsai.Bootstrap Get-Service { [pscustomobject]@{ Name = 'Stopped'; Status = 'Stopped' } }
        }

        It '啟動該服務' {
            Start-ManagedService -Name 'StoppedService' -DisplayName 'Stopped Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service -Times 1 -Exactly `
                -ParameterFilter { $Name -eq 'StoppedService' }
        }

        It '先回報 INFO 再回報 OK' {
            Start-ManagedService -Name 'StoppedService' -DisplayName 'Stopped Service'

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
                -ParameterFilter { $Level -eq 'INFO' -and $Message -eq 'Starting Stopped Service' }
            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
                -ParameterFilter { $Level -eq 'OK' -and $Message -eq 'Stopped Service started' }
        }

        It '-WhatIf 不會真的啟動服務' {
            Start-ManagedService -Name 'StoppedService' -DisplayName 'Stopped Service' -WhatIf

            Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Start-Service -Times 0 -Exactly
        }
    }
}
