function Get-SqlPlusCommands
<#
  .SYNOPSIS
    Get Sql plus commands
  
  .DESCRIPTION
    Get Sql plus commands to execute the files matching $splSpec in $ directory
  
  .EXAMPLE
    		PS C:\> Get-SqlPlusCommands

  .EXAMPLE
    Get-SqlPlusCommands | %{
    Write-Host "Attempting : ", $sqlplusExe . $_.sqlplusArgs
    try
    {
      Start-Executable "sqlplus.exe" $_.sqlplusArgs -verbose:$verbose -whatif:$whatif
    }
     
#>
{
  [CmdletBinding()]
  [OutputType([System.Collections.Hashtable])]
  param
  (
    [Parameter(Position = 1)]
    [string]$directory = $PWD,
    [Parameter(Position = 2)]
    [string[]]$sqlSpec = @("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql"),
    $logFileSuffix = "YYYY-MM-ddTHH-mm-ss",
    $netServiceNames = @{ pon = "PONX.world"; onc = "ONCX.world" }
  )
  #region Initialization code
  foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
  {
    $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
  }
  #endregion Initialization code
  ConvertTo-SqlPlusCommands @PsBoundParameters | Set-OracleUserPassword | Set-CommandLine
}