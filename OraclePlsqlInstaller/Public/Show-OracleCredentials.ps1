<#
  .SYNOPSIS
    Show the Oracle credentials from the Windows Vault
  
  .DESCRIPTION
    Show the Oracle credentials from the Windows Vault by SDLC
  
  .EXAMPLE
    		PS C:\> Show-OracleCredentials -sdlc "dev"
  
  .NOTES
    How to retrieve the password using BetterCredentials

    $username='pofpo_connect@pond.world'
    $Target="MicrosoftPowerShell:user=$Username"
    $cred= BetterCredentials\Get-Credential -username $Target
    $cred.GetNetworkCredential().password
    $cred.GetNetworkCredential().Username

#>
function Show-OracleCredentials
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 0)]
    [ValidateSet('dev', 'test', 'uat', 'prod', 'train')]
    [string]$sdlc
  )
  #region setup
  # Get the command name
  $CommandName = $PSCmdlet.MyInvocation.InvocationName;
  # Get the list of parameters for the command
  "${CommandName}: Input", (((Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters) |
    %{ Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue; } |
    Format-Table -AutoSize @{ Label = "Name"; Expression = { $_.Name }; }, @{ Label = "Value"; Expression = { (Get-Variable -Name $_.Name -EA SilentlyContinue).Value }; }) |
  Out-String | write-verbose
  #endregion
  
  $sdlc = $sdlc.ToUpper()
  $connectIdentifier = Set-SdlcConnections -sdlc $sdlc
  try
  {
    $connectIdentifier.GetEnumerator() | ForEach-Object {
      Write-Host $_.value
      $creds = BetterCredentials\Find-Credential -filter $('*{0}' -f $_.value)
      foreach ($cred in $creds)
      {
        $cred, $cred.GetNetworkCredential().Username, $cred.GetNetworkCredential().Password | format-list | Out-String | write-host
        $('sqlplus -L {0}/{1}@{2}' -f $cred.GetNetworkCredential().Username.Split('@')[0], $cred.GetNetworkCredential().Password , $cred.GetNetworkCredential().Username.Split('@')[1])| Out-String | write-host
      }
    }
  }
  catch
  {
    Write-Warning -Message "$_ $username"
  }
}
