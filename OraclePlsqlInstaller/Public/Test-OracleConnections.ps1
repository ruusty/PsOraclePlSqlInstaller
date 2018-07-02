<#
  .SYNOPSIS
    Test the connection strings can connect to the database and schema
    
  .DESCRIPTION
    Throws if connect to database fails
#>
function Test-OracleConnections
{
  [CmdletBinding(SupportsShouldProcess = $true)]
  [PSTypeName('PSOracle.SqlPlusCmd')]
  param
  (
    [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               Position = 0)]
    [PSTypeName('PSOracle.SqlPlusCmd')]
    $sqlPlusCommand,
    $sqlplusExe ="sqlplus.exe"
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
    $doneconnections =@()
  }
  PROCESS
  {
    #just want the unique username and tnsName combinations
    $sqlPlusCommand | %{
      $id = $_.OraConnection
      if ($id -notin $doneconnections)
      {
        $doneconnections += $id
        $cmd = $("echo.exit|{0} -L ""{1}""" -f $sqlplusExe, $id)
        Write-Verbose "Testing : $id"
        If ($PSCmdlet.ShouldProcess($("{0}" -f $cmd)))
        {
          & cmd.exe /c ""$cmd"" | out-default
          if ($lastexitcode -ne 0)
          {
            Write-Error -Message "$id failed with $lastexitcode" -Category AuthenticationError
          }
        }
      }
    }
  }
}