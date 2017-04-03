<#
  .SYNOPSIS
    Display the Oracle  username and password
  
  .DESCRIPTION
    Displays the username and password from the credential file.
    Attempts to extract the Oracle connection identifier matching
     '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)'
  
  .PARAMETER Path
    The path of the credential file
  
  .EXAMPLE
    PS C:\> .\show-OraSecret.ps1 russell@pond.world.credential
  
  .NOTES
    If the credential was not created by the user an error happens
#>
[CmdletBinding()]
param
(
  [Parameter(Mandatory = $true,
             Position = 1)]
  [string]$Path
)
Resolve-Path -Path $Path | %{
  $Credential = Import-Clixml $_
  $user = $Credential.GetNetworkCredential().username
  $PW = $Credential.GetNetworkCredential().Password
  $name = [System.IO.Path]::GetFileNameWithoutExtension($_)
  Write-Verbose $("`$name=$name" -f $name)
  #parse out the connection_identifier string
  $connect_identifier = "notset"
  if ($name -match '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)')
  {
    $connect_identifier = $matches[2]
  }
  Write-Host  $("{0}/{1}@{2}" -f $user, $PW, $connect_identifier)
}
