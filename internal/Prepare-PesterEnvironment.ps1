#Requires -Version 3.0

Set-StrictMode -Version 1.0

Function Prepare-PesterEnvironment (
    [PSCustomObject] $ModuleInfo
) {
    # Removes all versions of the module from the session before importing
    Get-Module -Name $($ModuleInfo.ModuleName) | Remove-Module

    # Because ModuleBase includes version number, this imports the required version
    # of the module
    $null = Import-Module -Name "$($ModuleInfo.ModulePath)\$($ModuleInfo.ModuleName).psd1" -PassThru -ErrorAction Stop 
    
    #. "$($ModuleInfo.ModulePath)\internal\DynamicParams.ps1"
    Get-ChildItem -Path "$($ModuleInfo.ModulePath)\internal" -File -Filter *.ps1 | ForEach-Object { . $_.FullName }    
}