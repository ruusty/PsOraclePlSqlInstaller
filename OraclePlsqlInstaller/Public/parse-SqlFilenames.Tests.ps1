$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "parse-SqlFilenames" {
    It "does something useful" {
        #$true | Should Be $false
        parse-SqlFilenames -directory $(join-path $PSScriptRoot "PlSql-Runner" ) -verbose
    }
}
