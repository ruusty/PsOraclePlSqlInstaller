<#
  .SYNOPSIS
    Creates Oracle  Username and Password to an encrypted file named after the OracleConnection
  
  .DESCRIPTION
    Persists the Oracle  Username and Password to an encrypted file named after the OracleConnection
  
  .PARAMETER OracleConnection
    Oracle connection to database
    E.G. rusty@pond.world
    rusty/pwd@pond.world
  
  .PARAMETER Directory
    Directory of the credential file, Defaults to the current location.
  
  .PARAMETER Force
    Overwrites existing file
  
  .PARAMETER Credential
    Oracle username and password
  
  .EXAMPLE
    PS C:\> Set-OracleSecret.ps1 -tns pond.world
  
  .NOTES
    $rgh=Get-OracleSecret rholliday@pond.world -f
    $rgh.GetNetworkCredential().Password
    $rgh.username

#>
function Get-OracleSecret
{
  [CmdletBinding(SupportsShouldProcess = $true)]
  param
  (
    [Parameter(Mandatory = $true)]
    [Alias('tns')]
    [string]$OracleConnection,
    [string]$Directory = $(get-location).Path,
    [switch]$Force
  )
  
  #region init
  $PSBoundParameters | Out-String | Write-Verbose
  #endregion init
  
    #Parse the connection IdentifierSystem.Security.Authentication.InvalidCredentialException
    #user/pwdservice.world
    #user service.world
    #/ service.world   Oracle Wallet
    
    #user@pond.world
    if ($OracleConnection -match '^([A-Za-z_0-9]*)@([A-Za-z0-9_\.]*$)')
    {
      $OracleUser = $matches[1]
      $OraclePwd = $null
      $connect_identifier = $matches[2]
    }
    #user/pwd@pond.world
    elseif ($OracleConnection -match '^([A-Za-z_0-9]*)/([A-Za-z_0-9]*)@([A-Za-z0-9_\.]*$)')
    {
      $OracleUser = $matches[1]
      $OraclePwd = $matches[2]
      $connect_identifier = $matches[3]
    }
    else
    {
      throw [System.Security.Authentication.InvalidCredentialException] "Invalid Oracle Connection format"
    }
  
  $credPath = Join-Path $Directory $($OracleUser + "`@$connect_identifier.credential")
  if ((Test-Path $credPath) -and $Force)
  {
    Remove-Item -path $credPath -Force
  }
  Get-Variable -name @("OracleUser", "connect_identifier", "credPath", "OraclePwd") | sort | Format-Table -property name, value, description -autosize | out-string | write-verbose
  
  if (!(Test-Path $credPath))
  {
    if ($OraclePwd -eq $null)
    {
      [pscredential]$Credential = $(Get-Credential -Message "Enter Oracle Username and Password for $OracleConnection " -UserName $OracleUser)
    }
    else
    {
      $Credential = new-object System.Management.Automation.PSCredential($OracleUser, $(convertto-securestring -String $OraclePwd -AsPlainText -Force))
      if (!$Credential) { throw [System.Security.Authentication.InvalidCredentialException] "Null credentials entered" }
    }
    $credential | Export-CliXml $credPath
  }
  $credential = Import-CliXml $credPath
  $credential
}

