function Get-OracleCredential
<#
  .SYNOPSIS
    Get the credential for an Oracle Username and Oracle Net Service Name
  
  .DESCRIPTION
    Get the credential for an Oracle Username and Oracle Net Service Name
    Will prompt for the password if not found in the Windows Vault
  
  .PARAMETER Username
    The user/schema name
  
  .PARAMETER net_service_name
    Oracle Net Service Name
  
  .EXAMPLE
    		Get-OracleCredential -Username "rholliday" -net_service_name "pond.world
  
  .NOTES
    $UserName = $(([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -split '\\')[1])
    $netServiceNames = OraclePlsqlInstaller\Set-SdlcConnections -sdlc $sdlc;
    $cred = Get-OracleCredential -Username $UserName -net_service_name $($netServiceNames.pon)
    $secret = $cred.GetNetworkCredential().Password
#>
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Username,
    [Parameter(Mandatory = $true,
               Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$netServiceName
  )
  
  $OraUserName = $('{0}@{1}' -f $UserName, $netServiceName)
  $Target = "MicrosoftPowerShell:user=$OraUsername"
  try
  {
    try
    {
      if (BetterCredentials\Find-Credential -filter $Target | out-null)
      {
        BetterCredentials\Test-Credential -username $Target | out-null
      }
    }
    catch
    {
      BetterCredentials\Get-Credential -username "$OraUsername" -Store -Force -inline -Description "Oracle $OraUsername" | out-null
    }
    BetterCredentials\Get-Credential -username "$OraUsername"
  }
  # Catch all other exceptions thrown by one of those commands
  catch
  {
    Write-Warning -Message "$_ $Target"
    Write-Error -Message "$OraUsername not found in Windows Vault (Control Panel\All Control Panel Items\Credential Manager).`r`nCreate Entry`r`nBetterCredentials\Get-Credential -username `"$OraUsername`" -Store -Force -inline -Description `"Spatial Admin user`"" -Category ConnectionError
  }
}