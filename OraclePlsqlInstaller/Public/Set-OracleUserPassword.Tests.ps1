<#
invoke-Pester -Script @{ Path = './Set-OracleUserPassword.Tests.ps1'; verbose = 'Continue' } 
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'

. "$PSScriptRoot\ConvertTo-SqlPlusCommands.ps1"
. "$here\$sut"

#Describe "Set-OracleUserPassword" {
#$InputTest = ConvertTo-SqlPlusCommands -directory $(join-path $PSScriptRoot "..\Specification") 
#$InputTest|gm|out-string|write-host
#    It "does something useful by command line" {
#    Set-OracleUserPassword -sqlPlusCommands $InputTest -verbose 
#    }
#}

Describe "Set-OracleUserPassword2" {
$InputTest = ConvertTo-SqlPlusCommands -directory $(join-path $PSScriptRoot "..\Specification") 
$InputTest.Count | write-host
$InputTest|gm|out-string|write-host

  It "does something useful args by pipeline" {
     $InputTest | Set-OracleUserPassword -verbose
    }
}
