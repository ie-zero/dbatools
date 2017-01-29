#Requires -Version 3.0
Set-StrictMode -Version 1.0

Function Prepare-PesterEnvironment (
    [string] $ModulePath
) {
    $moduleName = Split-Path -Path $ModulePath -Leaf

    # Removes all versions of the module from the session before importing
    Get-Module -Name $ModuleName | Remove-Module

    # Because ModuleBase includes version number, this imports the required version
    # of the module
    $null = Import-Module -Name "$ModulePath\$moduleName.psd1" -PassThru -ErrorAction Stop 
    
    #. "$($ModuleInfo.ModulePath)\internal\DynamicParams.ps1"
    Get-ChildItem -Path "$ModulePath\internal" -File -Filter *.ps1 | ForEach-Object { . $_.FullName }    
}