function Show-OracleSecret
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
    PS C:\> .\show-OracleSecret.ps1 russell@pond.world.credential
  
  .NOTES
    If the credential was not created by the user an error happens
#>
{
  [CmdletBinding()]
  param
  (
    [Parameter( ValueFromPipeline = $true,
               Position = 1)]
    [string[]]$Path = "*.credential"
  )
  BEGIN
  {
    #region Initialization code
    $PSBoundParameters | format-list -Expand CoreOnly -Property Keys, Values | Out-String | Write-Verbose
    foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
    {
      $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
    }
    Write-Verbose $("in-process {0}" -f $PSCmdlet.MyInvocation.InvocationName)
    #endregion Initialization code
  }
  PROCESS
  {
    Resolve-Path -Path $Path | %{
      $Credential = Import-Clixml $_
      $user = $Credential.GetNetworkCredential().username
      $pwd = $Credential.GetNetworkCredential().Password
      $name = [System.IO.Path]::GetFileNameWithoutExtension($_)
      Write-Verbose $("`$name=$name" -f $name)
      #parse out the connection_identifier string
      $connect_identifier = "notset"
      if ($name -match '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)')
      {
        $connect_identifier = $matches[2]
      }
      $("{0}/{1}@{2}" -f $user, $pwd, $connect_identifier)
    }
  }
}