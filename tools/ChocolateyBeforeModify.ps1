$ErrorActionPreference = 'Stop'
 
$tools = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
.  $(Join-Path $tools "properties.ps1")

# module may already be installed outside of Chocolatey
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue