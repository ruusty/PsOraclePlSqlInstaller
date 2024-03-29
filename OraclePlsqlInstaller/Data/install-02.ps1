<#
  .SYNOPSIS
    Executes SqlPlus.exe with pl/sql files
  
  .DESCRIPTION
    Automates executing SqlPlus.exe with pl/sql files
  
  .PARAMETER tasklist
    Psake task
  
  .PARAMETER sdlc
    The System Development configuration
  
  .Example
    .\install.ps1 -?
    
  .Example
    .\install.ps1 -task install -sdlc dev -verbose -whatif
  
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
  [ValidateSet('UNSET','DEV', 'UAT','PROD')]
  [string]$sdlc = 'UNSET'
)
#region startup
$CommandName = $PSCmdlet.MyInvocation.InvocationName;
# Get the list of parameters for the command
"${CommandName}: Input", (((Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters) |
  ForEach-Object{ Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue; } |
  Format-Table -AutoSize @{ Label = "Name"; Expression = { $_.Name }; }, @{ Label = "Value"; Expression = { (Get-Variable -Name $_.Name -EA SilentlyContinue).Value }; }) |
Out-String | write-verbose
#endregion


$params = @{
  WhatIfPreference       = $WhatIfPreference;
  VerbosePreference      = $VerbosePreference;
  DebugPreference        = $DebugPreference;
  JobName                = [System.IO.path]::GetFileNameWithoutExtension($PSCommandPath)
  sdlc                   = $sdlc
}

$props = @{
  cfg_sqlSpec = @('[0-9_][0-9_][0-9_]_*-*.sql')
}

$netServiceName = (OraclePlsqlInstaller\Set-SdlcConnections -sdlc $sdlc).srr;
$params.SrrCredential = OraclePlsqlInstaller\Get-OracleCredential -Username 'oms_user' -netservicename $netServiceName

Invoke-psake -nologo -buildFile 'sqlplus.psakefile.ps1' -parameters $params -properties $props -taskList $tasklist