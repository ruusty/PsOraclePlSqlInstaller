$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

#cd testDrive;
#test file exists
Describe "New-OracleRunFixture" {
    It "does something useful" {
        $true | Should Be $false
    }
}
