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
  }
  PROCESS
  {
    $("echo.exit|{0} -L ""{1}/{2}@{3}""" -f $sqlplusExe, $sqlPlusCommand.oraUser, $sqlPlusCommand.Orapassword, $sqlPlusCommand.tnsName) | sort -Unique | %{
      $cmd=$_
      Write-Host "Testing : cmd.exe /c $_"
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