<#
invoke-Pester -Script @{ Path = './ConvertTo-SqlPlusCommands.Tests.ps1'; verbose = [System.Management.Automation.ActionPreference]::Continue } 
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'


. "$here\$sut"

Describe "ConvertTo-SqlPlusCommands verbose"{
    It "does something useful" {
        ConvertTo-SqlPlusCommands -directory $(join-path $PSScriptRoot "..\Specification\Data") -verbose | write-host
    }
}

Describe "ConvertTo-SqlPlusCommands" {
    It "does something useful" {
        ConvertTo-SqlPlusCommands -directory $(join-path $PSScriptRoot "..\SpecificationSpecification\Data")  | gm | write-host
        #TODO
    }
}
