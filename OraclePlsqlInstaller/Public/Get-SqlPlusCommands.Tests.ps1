<#
invoke-Pester -Script @{ Path = './Get-SqlPlusCommands.Tests.ps1'; verbose = [System.Management.Automation.ActionPreference]::Continue } 
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

. "$PSScriptRoot\ConvertTo-SqlPlusCommands.ps1"
. "$PSScriptRoot\Set-OracleUserPassword.ps1"
. "$PSScriptRoot\Set-CommandLine.ps1"

Describe "Get-SqlPlusCommands" {
$getArgs=@{
   directory = $(join-path $PSScriptRoot "..\Specification") 
   sqlSpec = @("[0-9_][0-9_][0-9_]_*-*.sql");
    logFileSuffix = "YYYY-MM-ddTHH-mm-ss";
    netServiceNames = @{ pon = "POND.world"; onc = "ONCD.world" };
}
    It "does something useful with Get-SqlPlusCommands" {
        #$true | Should Be $false
        #Get-SqlPlusCommands @getArgs -verbose | format-list -Expand CoreOnly -Property Keys, Values | Out-String | write-host
        Get-SqlPlusCommands @getArgs -verbose | format-table  -Property filename,oraUser,oraPassword,tnsName -Wrap | Out-String -width 1000 | write-host
        #Get-SqlPlusCommands @getArgs -verbose | format-list -Expand CoreOnly | Out-String | write-host
    }
}
