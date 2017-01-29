#Requires -Version 3.0
#Requires -Module Pester 
#Requires -Module PSScriptAnalyzer

Set-StrictMode -Version 1.0

function Execute-ScriptAnalyzerTests(
    [string] $Name,
    [string] $Path,
    [string[]] $ExcludeRule
) {
    $rules = Get-ScriptAnalyzerRule | Where{ $_.RuleName -notin @($ExcludeRule) }

    Describe 'Script Analyzer Tests' {
	    Context "Testing '$name' for Standard Processing" {
		    foreach ($rule in $rules) { 
			    $index = $rules.IndexOf($rule)
			    It "Processing PSScriptAnalyzer rule number $($index +1) - $rule	" {
				    #@(Invoke-ScriptAnalyzer -Path "$PSScriptRoot\..\functions\$sut" -IncludeRule $rule.RuleName).Count | Should Be 0 
                    @(Invoke-ScriptAnalyzer -Path $Path -IncludeRule $rule.RuleName).Count | Should Be 0 
			    }
		    }
	    }
    }
}