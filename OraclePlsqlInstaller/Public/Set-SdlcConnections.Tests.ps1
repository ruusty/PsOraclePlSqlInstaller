$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Set-SdlcConnections" {
    It "does something useful" {
    Set-SdlcConnections "DEV" -verbose
    }
}
