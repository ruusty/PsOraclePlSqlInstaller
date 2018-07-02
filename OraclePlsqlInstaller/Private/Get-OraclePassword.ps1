<#
  .SYNOPSIS
    Get the Oracle schema passwords
  
  .DESCRIPTION
    Gets the Oracle schema passwords using BetterCredentials

  .EXAMPLE
    PS C:\> 
  
#>
function Get-OraclePassword
{
  [CmdletBinding()]
  [PSTypeName('PSOracle.SqlPlusCmd')]
  param
  (
    [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               Position = 0)]
    [PSTypeName('PSOracle.SqlPlusCmd')]
    $sqlPlusCommand
  )
  BEGIN
  {
    $ErrorActionPreference = 'Stop'
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
    $UserName = $sqlPlusCommand.OraFQUserName
    if (!($sqlPlusCommand.IsInOraWallet ))
    {
      #Not in Oracle Wallet get from Windows Vault
      $Target = "MicrosoftPowerShell:user=$Username"
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
          BetterCredentials\Get-Credential -username "$Username" -Store -Force -inline -Description "Oracle user" | out-null
        }
      }
      # Catch all other exceptions thrown by one of those commands
      catch
      {
        Write-Warning -Message "$_ $Target"
        Write-Error -Message "$Username not found in Windows Vault (Control Panel\All Control Panel Items\Credential Manager).`r`nCreate Entry`r`nBetterCredentials\Get-Credential -username `"$Username`" -Store -Force -inline -Description `"Spatial Admin user`"" -Category ConnectionError
      }
      $sqlPlusCommand.OraPassword = (BetterCredentials\Get-Credential -UserName $Username).GetNetworkCredential().Password
    }
    $sqlPlusCommand
  }
}
