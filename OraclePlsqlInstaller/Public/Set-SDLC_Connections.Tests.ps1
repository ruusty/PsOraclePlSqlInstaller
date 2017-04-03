$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Set-SDLC_Connections" {
    It "does something useful" {
    Set-SDLC_Connections "DEV" -verbose
    }
}
