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
      $id = $("{0}/{1}" -f $_.oraUser, $_.tnsName)
      if ($id -notin $doneconnections)
      {
        $doneconnections += $id
        $cmd = $("echo.exit|{0} -L ""{1}/{2}@{3}""" -f $sqlplusExe, $_.oraUser, $_.Orapassword, $_.tnsName)
        #Write-Host "Testing : cmd.exe /c $_"
        If ($PSCmdlet.ShouldProcess($("{0}" -f $cmd)))
        {
          & cmd.exe /c ""$cmd"" | out-default
          if ($lastexitcode -ne 0)
          {
            throw ("Exec: " + "Exited with a failure of $lastexitcode running: cmd.exe /c $cmd")
          }
        }
      }
    }
  }
}