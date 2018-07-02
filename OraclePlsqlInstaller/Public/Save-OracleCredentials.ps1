<#
  .SYNOPSIS
    Saves the Oracle credentials into the Windows Vault
  
  .DESCRIPTION
    Saves the Oracle credentials into the Windows Vault
  
  .EXAMPLE
    		PS C:\> Save-OracleCredentials -sdlc "dev"
  
  .NOTES
    How to retrieve the password using BetterCredentials

    $username='pofpo_connect@pond.world'
    $Target="MicrosoftPowerShell:user=$Username"
    $cred= BetterCredentials\Get-Credential -username $Target
    $cred.GetNetworkCredential().password
    $cred.GetNetworkCredential().Username

#>
function Save-OracleCredentials
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    [ValidateScript({ (Test-Path $_) })]
    [string]$Path,
    [Parameter(Mandatory = $true,
               Position = 2)]
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
  $xp_sdlc_config = "/environments/sdlc[@name='$sdlc']/connection"
  $xmlFrag = Select-Xml -XPath $xp_sdlc_config -Path $Path | Select -Expand Node
  $xmlFrag | Out-String | write-verbose
  try
  {
    foreach ($i in $xmlFrag)
    {
      $username = $('{0}@{1}' -f $i.username, $i.tnsAlias)
      Write-Verbose "Attempting to create credentials for: $username"
      $bcArgs = @{
        UserName   = $Username
        Store      = $true
        Force      = $true
        Password   = $i.password
      }
      $cred = BetterCredentials\Get-Credential @bcArgs
      $cred | Out-String | Write-verbose
    }
  }
  catch
  {
    Write-Warning -Message "$_ $username"
  }
}
