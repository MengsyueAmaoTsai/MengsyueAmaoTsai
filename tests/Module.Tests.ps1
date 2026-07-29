BeforeAll {
    $script:repositoryRoot = Split-Path -Parent $PSScriptRoot
    $script:manifestPath = Join-Path $script:repositoryRoot 'src\Bootstrappers\Windows\MengsyueAmaoTsai.Bootstrap\MengsyueAmaoTsai.Bootstrap.psd1'

    Import-Module $script:manifestPath -Force
}

AfterAll {
    Remove-Module MengsyueAmaoTsai.Bootstrap -Force -ErrorAction SilentlyContinue
}

Describe 'MengsyueAmaoTsai.Bootstrap 模組' {

    It 'manifest 有效' {
        { Test-ModuleManifest -Path $script:manifestPath } | Should -Not -Throw
    }

    It '實際匯出的函式與 manifest 宣告一致' {
        $declared = @((Import-PowerShellDataFile -Path $script:manifestPath).FunctionsToExport) | Sort-Object
        $exported = @((Get-Command -Module MengsyueAmaoTsai.Bootstrap).Name) | Sort-Object

        $exported | Should -Be $declared
    }

    It '不匯出 Private 函式' {
        Get-Command -Module MengsyueAmaoTsai.Bootstrap -Name 'Assert-NativeCommandSuccess' -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
    }

    It '所有匯出函式都使用核准動詞' {
        $approvedVerbs = (Get-Verb).Verb
        $offenders = @((Get-Command -Module MengsyueAmaoTsai.Bootstrap).Name |
                Where-Object { ($_ -split '-')[0] -notin $approvedVerbs })

        $offenders | Should -BeNullOrEmpty -Because "非核准動詞會讓 Get-Command 的探索行為不一致：$($offenders -join ', ')"
    }

    It '每個匯出函式都有 comment-based help 的 SYNOPSIS' {
        $missing = @((Get-Command -Module MengsyueAmaoTsai.Bootstrap).Name |
                Where-Object { -not (Get-Help $_ -ErrorAction SilentlyContinue).Synopsis.Trim() })

        $missing | Should -BeNullOrEmpty
    }
}

Describe 'Repository 內的 PowerShell 檔案' {

    It '全部通過語法解析' {
        $failures = @()

        foreach ($file in Get-ChildItem -Path $script:repositoryRoot -Recurse -File -Include *.ps1, *.psm1) {
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$parseErrors) | Out-Null

            if ($parseErrors) {
                $failures += "$($file.Name):$($parseErrors[0].Extent.StartLineNumber) $($parseErrors[0].Message)"
            }
        }

        $failures | Should -BeNullOrEmpty
    }

    It '含非 ASCII 內容的檔案都有 UTF-8 BOM' {
        $missingBom = @()

        foreach ($file in Get-ChildItem -Path $script:repositoryRoot -Recurse -File -Include *.ps1, *.psm1, *.psd1) {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
            $hasNonAscii = @([System.IO.File]::ReadAllText($file.FullName).ToCharArray() | Where-Object { [int]$_ -gt 127 }).Count -gt 0

            if ($hasNonAscii -and -not $hasBom) {
                $missingBom += $file.Name
            }
        }

        $missingBom | Should -BeNullOrEmpty -Because 'Windows PowerShell 5.1 讀無 BOM 檔會套用 ANSI code page，中文註解會變亂碼'
    }
}
