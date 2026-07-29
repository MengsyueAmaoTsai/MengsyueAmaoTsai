BeforeAll {
    $manifestPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'src\Bootstrappers\Windows\MengsyueAmaoTsai.Bootstrap\MengsyueAmaoTsai.Bootstrap.psd1'
    Import-Module $manifestPath -Force
}

AfterAll {
    Remove-Module MengsyueAmaoTsai.Bootstrap -Force -ErrorAction SilentlyContinue
}

Describe 'Update-RemoteConfigFile' {

    BeforeEach {
        $script:sandbox = Join-Path ([System.IO.Path]::GetTempPath()) "bootstrap-tests-$([guid]::NewGuid().ToString('N'))"
        New-Item -ItemType Directory -Path $script:sandbox -Force | Out-Null

        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus { }
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Invoke-WebRequest {
            Set-Content -LiteralPath $OutFile -Value 'DOWNLOADED' -NoNewline
        }
    }

    AfterEach {
        Remove-Item -LiteralPath $script:sandbox -Recurse -Force -ErrorAction SilentlyContinue
    }

    It '寫入每一個目的地' {
        $first = Join-Path $script:sandbox 'first.txt'
        $second = Join-Path $script:sandbox 'second.txt'

        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' -Destination @($first, $second)

        Get-Content -LiteralPath $first -Raw | Should -Be 'DOWNLOADED'
        Get-Content -LiteralPath $second -Raw | Should -Be 'DOWNLOADED'
    }

    It '只下載一次就散佈到多個目的地' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt'), (Join-Path $script:sandbox 'b.txt'))

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Invoke-WebRequest -Times 1 -Exactly
    }

    It '多個目的地時狀態訊息帶出數量' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt'), (Join-Path $script:sandbox 'b.txt'))

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'OK' -and $Message -eq 'Test config updated (2 targets)' }
    }

    It '單一目的地時狀態訊息不帶數量' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt'))

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'OK' -and $Message -eq 'Test config updated' }
    }

    It '加上一次性查詢參數避開快取' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt'))

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Invoke-WebRequest -Times 1 -Exactly `
            -ParameterFilter { $Uri -match '\?bootstrapper=[0-9a-f]{32}$' }
    }

    It '來源 URL 已有查詢字串時改用 & 串接' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config?ref=master' `
            -Destination @((Join-Path $script:sandbox 'a.txt'))

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Invoke-WebRequest -Times 1 -Exactly `
            -ParameterFilter { $Uri -match '\?ref=master&bootstrapper=' }
    }

    It '驗證收到的是已下載內容的暫存檔' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt')) `
            -Validate {
            param($Path)

            if (-not (Test-Path -LiteralPath $Path)) { throw "暫存檔不存在: $Path" }
            if ((Get-Content -LiteralPath $Path -Raw) -ne 'DOWNLOADED') { throw '暫存檔內容不符' }
        }

        Should -Invoke -ModuleName MengsyueAmaoTsai.Bootstrap Write-BootstrapperStatus -Times 1 -Exactly `
            -ParameterFilter { $Level -eq 'OK' }
    }

    It '驗證失敗時 throw' {
        {
            Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
                -Destination @((Join-Path $script:sandbox 'a.txt')) `
                -Validate { throw 'simulated validation failure' }
        } | Should -Throw '*simulated validation failure*'
    }

    It '驗證失敗時不覆蓋既有檔案' {
        $guarded = Join-Path $script:sandbox 'guarded.txt'
        Set-Content -LiteralPath $guarded -Value 'ORIGINAL' -NoNewline

        { Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
                -Destination @($guarded) -Validate { throw 'nope' } } | Should -Throw

        Get-Content -LiteralPath $guarded -Raw | Should -Be 'ORIGINAL'
    }

    It '下載失敗時 throw 並帶出描述' {
        Mock -ModuleName MengsyueAmaoTsai.Bootstrap Invoke-WebRequest { throw 'network down' }

        { Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
                -Destination @((Join-Path $script:sandbox 'a.txt')) } |
            Should -Throw '*Failed to update Test config*network down*'
    }

    It '成功時清除暫存檔' {
        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @((Join-Path $script:sandbox 'a.txt'))

        @(Get-ChildItem -LiteralPath $script:sandbox -Filter '.bootstrapper.*' -Force) | Should -BeNullOrEmpty
    }

    It '失敗時也清除暫存檔' {
        { Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
                -Destination @((Join-Path $script:sandbox 'a.txt')) -Validate { throw 'nope' } } | Should -Throw

        @(Get-ChildItem -LiteralPath $script:sandbox -Filter '.bootstrapper.*' -Force) | Should -BeNullOrEmpty
    }

    It '-WhatIf 不寫入目的地' {
        $target = Join-Path $script:sandbox 'whatif.txt'

        Update-RemoteConfigFile -Description 'Test config' -Uri 'https://example.invalid/config' `
            -Destination @($target) -WhatIf

        Test-Path -LiteralPath $target | Should -BeFalse
    }
}
