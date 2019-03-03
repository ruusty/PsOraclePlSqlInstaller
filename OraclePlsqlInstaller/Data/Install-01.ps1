<#
  .SYNOPSIS
    Executes SqlPlus.exe with pl/sql files
  
  .DESCRIPTION
    Automates executing SqlPlus.exe with pl/sql files
  
  .PARAMETER tasklist
    Psake task
  
  .PARAMETER sequence
    The pl/sql are run in sequence
    The sequence number determines the pl/sql files to execute using configuration in install.psd1
    '11', '12', '13', '14', '31', '32', '40', '70'

  .PARAMETER sdlc
    The System Development configuration
  
  .Example
    .\install.ps1 -?
    
  .Example
    .\install.ps1 -task install -seq 11 -sdlc dev -verbose -whatif
  
  .NOTES
    Whatif and Verbose switches are supported.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param
(
  [Parameter(Position = 0)]
  [String[]]$tasklist = '?',
  [Parameter(Mandatory = $false,
             Position = 1)]
  [ValidateSet('unset','11', '12', '13', '14', '31', '32', '40', '70', 'all')]
  [string]$sequence = 'unset',
  [Parameter(Mandatory = $false,
             Position = 2)]
  [ValidateSet('UNSET','DEV', 'PROD')]
  [string]$sdlc = 'UNSET',
  [switch]$Force
)
#region startup
$CommandName = $PSCmdlet.MyInvocation.InvocationName;
# Get the list of parameters for the command
"${CommandName}: Input", (((Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters) |
  ForEach-Object{ Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue; } |
  Format-Table -AutoSize @{ Label = "Name"; Expression = { $_.Name }; }, @{ Label = "Value"; Expression = { (Get-Variable -Name $_.Name -EA SilentlyContinue).Value }; }) |
Out-String | write-verbose
#endregion

$name = 'sql_{0}' -f $sequence
$ConfigPath = [System.IO.Path]::ChangeExtension($PSCommandPath, ".psd1")
$ConfigData = (Import-PowerShellDataFile -Path $ConfigPath).$name
if (!$ConfigData)
{
  $ConfigData =  'not_found.sql'
}


$params = @{
  WhatIfPreference       = $WhatIfPreference;
  VerbosePreference      = $VerbosePreference;
  DebugPreference        = $DebugPreference;
  JobName                = '{0}-{1}' -f $([System.IO.path]::GetFileNameWithoutExtension($PSCommandPath)), $sequence
  sdlc                   = $sdlc
}

$props = @{
  cfg_sqlSpec = $ConfigData
  force = $force
}


Invoke-psake -nologo -buildFile 'sqlplus.psakefile.ps1' -parameters $params -properties $props -taskList $tasklist