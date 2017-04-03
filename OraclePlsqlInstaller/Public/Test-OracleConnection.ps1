function Test-OracleConnections
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    $sqlFileInfo
  )
  $credentialPaths = $sqlFileInfo | %{ $i.pwdFname } | sort -Unique
    $sqlFileInfo | %{
    "echo.exit|sqlplus.exe -L {0}/{1}@{2}" -f $_.db_user, $_.password, $_.database_sdlc
  } | Sort-Object -Unique | %{
      Write-Host "cmd.exe /c " $_
#    & cmd.exe /c ""$cmd""
#    if ($lastexitcode -ne 0)
#    {
#      throw ("Exec: " + "sqlplus.exe exited with a failure of $lastexitcode running: cmd.exe /c $cmd")
#    }
  }
}