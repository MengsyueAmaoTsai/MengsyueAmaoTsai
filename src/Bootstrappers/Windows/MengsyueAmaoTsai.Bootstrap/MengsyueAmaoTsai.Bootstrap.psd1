@{
    RootModule        = 'MengsyueAmaoTsai.Bootstrap.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'ff03cf78-ed1a-45cc-8d79-0b6bc62121ab'
    Author            = 'Mengsyue Amao Tsai'
    Description       = 'Building blocks for the Windows workstation bootstrapper: remote configuration files, optional services and developer tooling.'
    PowerShellVersion = '5.1'

    # 明確列出而不用萬用字元：模組探索不必載入整個模組就能知道有哪些命令。
    FunctionsToExport = @(
        'Initialize-GpgAgent'
        'Initialize-SshAgent'
        'Set-GitGlobalConfiguration'
        'Start-ManagedService'
        'Update-RemoteConfigFile'
        'Write-BootstrapperBanner'
        'Write-BootstrapperSection'
        'Write-BootstrapperStatus'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{
        PSData = @{
            ProjectUri = 'https://github.com/MengsyueAmaoTsai/MengsyueAmaoTsai'
        }
    }
}
