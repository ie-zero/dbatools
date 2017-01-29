#Requires -Version 3.0
#Requires -Module Pester 
#Requires -Module PSScriptAnalyzer

Set-StrictMode -Version 1.0

function Execute-ScriptAnalyzerTests(
    [string] $Path,
    [string[]] $ExcludeRule
) {
    $functionName = (Split-Path -Path $Path -Leaf) -replace '.ps1$'
    $rules = Get-ScriptAnalyzerRule | Where{ $_.RuleName -notin @($ExcludeRule) }

    Describe 'Script Analyzer Tests' {
	    Context "Testing '$functionName' for Standard Processing" {
		    foreach ($rule in $rules) { 
			    $index = $rules.IndexOf($rule)
			    It "Processing PSScriptAnalyzer rule number $($index +1) - $rule	" {
                    @(Invoke-ScriptAnalyzer -Path $Path -IncludeRule $rule.RuleName).Count | Should Be 0 
			    }
		    }
	    }
    }
}