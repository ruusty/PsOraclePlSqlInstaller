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
    $ErrorActionPreference = 'Stop'
    #region Initialization code
    foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
    {
      $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
    }
    #endregion Initialization code  
  }
  PROCESS
  {
    Write-Verbose $("Getting password for {0,-100}" -f $sqlPlusCommand.OraFQUserName)
    try
    {
      if ($sqlPlusCommand.IsInOraWallet)
      {
        $sqlPlusCommand.OraConnection = $('"/@{0}"' -f $sqlPlusCommand.tnsName)
      }
      else
      {
        $sqlPlusCommand.OraConnection = $('"{0}/{1}@{2}"' -f $sqlPlusCommand.oraUser, $sqlPlusCommand.oraPassword, $sqlPlusCommand.tnsName)
      }
      $sqlPlusCommand.sqlplusArgs = @("-L", $sqlPlusCommand.OraConnection, '@"run.sql"', $('"{0}"' -f $sqlPlusCommand.fileName), $('"{0}"' -f $sqlPlusCommand.logFileName))
    }
    catch {
      Write-Error -Message $("DOH! {0} " -f $sqlPlusCommand.FileName)
      throw
    }
    $sqlPlusCommand
  }
}