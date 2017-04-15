<#
invoke-Pester -Script @{ Path = './Get-BuildList.Tests.ps1'; verbose ='Continue' } 
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-BuildList" {
  pushd ..\Specification
    It "Should create Specification.lis" {
      
        #$true | Should Be $false
        Get-BuildList -BuildPath "Specification.build" 
    }

    It "Should create CR00000-__ProjectName__-Ora.lis" {
        #$true | Should Be $false
        Get-BuildList 
    }

    It "Should create CR00000-__ProjectName__-Ora.lis with verbosity"  {
      
        #$true | Should Be $false
        Get-BuildList -verbose
    }

    It "Should throw create CR00000-__ProjectName__-Ora.lis with verbosity"  {
      {
        Get-BuildList -buildPath not-found.build -Path ("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql","not_found.sql") -verbose
      } | should throw

    }

  popd
}
