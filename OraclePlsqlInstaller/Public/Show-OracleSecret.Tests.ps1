<#
Invoke-Pester                                -Script @{ Path = './Show-OracleSecret.Tests.ps1' }
Invoke-Pester    -testname "Show-OraSecret"  -Script @{ Path = './Show-OracleSecret.Tests.ps1' }
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
$SpecificationDir = Join-Path $here "..\Specification\"
$SpecificationPaths = '{0}/{1}' -f $SpecificationDir , "*X.world.credential"
$credentialFiles = Resolve-Path $SpecificationPaths |%{$_.Path}

Describe "Show-OracleSecret" {
  It "does something useful" {
    { Show-OracleSecret  } | Should not throw
    { Show-OracleSecret $credentialFiles } | Should not throw
    
  }
  
  It "Displays the username and password"{
    $rv = Show-OracleSecret -Path $credentialFiles 
    $rv | Should not be $null
    $rv | write-host
  }
}
