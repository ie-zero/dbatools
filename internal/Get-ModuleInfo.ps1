
Function Get-ModuleInfo(
    [string] $Path
) {
    ## Load the command
    $ModuleBase = $Path

    # For tests in .\Tests sub-directory
    if ((Split-Path $ModuleBase -Leaf) -in ('tests', 'internal', 'functions')) {
	    $ModuleBase = Split-Path -Path $ModuleBase -Parent
    }

    # Handles modules in version directories
    $leaf = Split-Path -Path $ModuleBase -Leaf
    $parent = Split-Path -Path $ModuleBase -Parent
    $parsedVersion = $null
    if ([System.Version]::TryParse($leaf, [ref]$parsedVersion)) {
	    $ModuleName = Split-Path -Path $parent -Leaf
    }
    else {
	    $ModuleName = $leaf
    }

    Write-Output -OutVariable [PSCustomObject] @{
        ModulePath = $ModuleBase
        ModuleName = $ModuleName
        ModuleVersion = $parsedVersion
    }
}