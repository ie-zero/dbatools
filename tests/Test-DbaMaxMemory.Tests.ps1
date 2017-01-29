#Requires -Version 3.0
#Requires -Module Pester 
#Requires -Module PSScriptAnalyzer

Set-StrictMode -Version 1.0

## Thank you Warren http://ramblingcookiemonster.github.io/Testing-DSC-with-Pester-and-AppVeyor/

$verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike 'master') {
	$verbose.add("Verbose", $true)
}

$path = (Get-Item -Path $MyInvocation.MyCommand.Path).FullName

if(-not $PSScriptRoot) {
	$PSScriptRoot = Split-Path -Path $path -Parent
}

$modulePath = Split-Path -Path $path -Parent
$functionName = (Split-Path -Path $path -Leaf) -replace '.Tests.ps1$'

# When the tests are located in .\Tests sub-directory.
if ((Split-Path $modulePath -Leaf) -eq 'Tests') {
	$modulePath = Split-Path -Path $modulePath -Parent
}

# Added PSAvoidUsingPlainTextForPassword as credential is an object and therefore fails. 
# We can ignore any rules here under special circumstances agreed by admins :-)
$rulesExcluded = @('PSAvoidUsingPlainTextForPassword')

Import-Module -Name "$modulePath\internal\Execute-ScriptAnalyzerTests.ps1" -Force
Execute-ScriptAnalyzerTests -Path "$modulePath\functions\$functionName.ps1" -ExcludeRule $rulesExcluded

Import-Module -Name "$modulePath\internal\Prepare-PesterEnvironment.ps1" -Force
Prepare-PesterEnvironment -ModulePath $modulePath

Import-Module -Name "$modulePath\functions\$functionName.ps1" -Force

## Validate functionality. 
Describe $functionName {
	InModuleScope dbatools {
		Context 'Validate input arguments' {
            It 'No "SQL Server" Windows service is running on the host' {
                Mock Get-Service { throw ParameterArgumentValidationError }
                { Test-DbaMaxMemory -SqlServer '' -WarningAction Stop 3> $null } | Should Throw
            }

			It 'SqlServer parameter is empty' {
				Mock Get-DbaMaxMemory -MockWith { return $null } 			
				Test-DbaMaxMemory -SqlServer '' 3> $null | Should be $null
			}

			It 'SqlServer parameter host cannot be found' {
				Mock Get-DbaMaxMemory -MockWith { return $null } 			
				Test-DbaMaxMemory -SqlServer 'ABC' 3> $null | Should be $null
			}

		}

		Context 'Validate functionality - Single Instance' {            
            Mock Resolve-SqlIpAddress -MockWith { return '10.0.0.1' } 
            Mock Get-Service -MockWith { 
                # Mocking Get-Service using PSCustomObject does not work. It needs to be mocked as object instead.               
                $service = New-Object System.ServiceProcess.ServiceController
                $service.DisplayName = 'SQL Server (ABC)'
                Add-Member -InputObject $service -MemberType NoteProperty -Name Status -Value 'Running'  -Force
                return $service
            } 

            It 'Connect to SQL Server' {
                Mock Get-DbaMaxMemory -MockWith { }

                $result = Test-DbaMaxMemory -SqlServer 'ABC'                

                Assert-MockCalled Resolve-SqlIpAddress -Scope It -Times 1                 
                Assert-MockCalled Get-Service -Scope It -Times 1 
                Assert-MockCalled Get-DbaMaxMemory -Scope It -Times 1 
            }
            
			It 'Connect to SQL Server and retrieve the "Max Server Memory" setting' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ SqlMaxMB = 2147483647 } 
                }

                (Test-DbaMaxMemory -SqlServer 'ABC').SqlMaxMB | Should be 2147483647               
			}
		
            It 'Calculate recommended memory - Single instance, Total 4GB, Expected 2GB, Reserved 2GB (.5x Memory)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 4096 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 2048
            }

            It 'Calculate recommended memory - Single instance, Total 6GB, Expected 3GB, Reserved 3GB (Iterations => 2x 8GB)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 6144 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 3072
            }

            It 'Calculate recommended memory - Single instance, Total 8GB, Expected 5GB, Reserved 3GB (Iterations => 2x 8GB)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 8192 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 5120
            }

            It 'Calculate recommended memory - Single instance, Total 16GB, Expected 11GB, Reserved 5GB (Iterations => 4x 8GB)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 16384 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 11264
            }

            It 'Calculate recommended memory - Single instance, Total 18GB, Expected 13GB, Reserved 5GB (Iterations => 1x 16GB, 3x 8GB)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 18432 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 13312
            }

            It 'Calculate recommended memory - Single instance, Total 32GB, Expected 25GB, Reserved 7GB (Iterations => 2x 16GB, 4x 8GB)' {
                Mock Get-DbaMaxMemory -MockWith { 
                    return @{ TotalMB = 32768 } 
                }                

                $result = Test-DbaMaxMemory -SqlServer 'ABC'
                $result.InstanceCount | Should Be 1
                $result.RecommendedMB | Should Be 25600
            }
		}
	}
}
