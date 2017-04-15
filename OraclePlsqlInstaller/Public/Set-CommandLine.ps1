function Set-CommandLine
<#
  .SYNOPSIS
    Set the commands line in the sqlFileInfo Hash Table
  
  .DESCRIPTION
    Creates the sqlPlusArgs for sqlplus.exe
  
  .PARAMETER sqlPlusCommands
    A description of the sqlPlusCommands parameter.
  
  
  .EXAMPLE
    PS C:\> Set-CommandLines -sqlPlusCommand $value1
  
#>
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
  begin
  {
    Write-Verbose $("in-process {0}" -f $PSCmdlet.MyInvocation.InvocationName)
  }
  PROCESS
  {
    
    Write-Verbose $("Getting password from {0,-100} for {1}" -f $sqlPlusCommand.credentialFileName, $sqlPlusCommand.path)
    try
    {
      $Credential = Import-Clixml $sqlPlusCommand.credentialFileName -ErrorAction Stop
      $sqlPlusCommand.oraPassword = $Credential.GetNetworkCredential().Password
      $conn = $('"{0}/{1}@{2}"' -f $sqlPlusCommand.oraUser, $Credential.GetNetworkCredential().Password, $sqlPlusCommand.tnsName)
      $sqlPlusCommand.sqlplusArgs = @("-L", $conn, '@"run.sql"', $('"{0}"' -f $sqlPlusCommand.fileName), $('"{0}"' -f $sqlPlusCommand.logFileName))
      $sqlPlusCommand
    }
    catch [System.Security.Cryptography.CryptographicException]{
      Write-Error -Message $("DOH! {0} probably created by another user: {1}`r`n{2}" -f $sqlPlusCommand.pwdFname, $_.Exception.GetType().FullName, $_.ToString())
      throw $_
    }
    catch
    {
      throw $_
    }
  }
}