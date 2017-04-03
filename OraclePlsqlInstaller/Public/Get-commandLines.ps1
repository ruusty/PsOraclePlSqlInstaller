function Get-CommandLines
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    $sqlFileInfo
  )
  $sqlFileInfo | %{
    if (Test-Path "..\$_.pwdFname") { $_.pwdFname = "..\$_.pwdFname" }
    $Credential = Import-Clixml $_.pwdFname -ErrorAction Stop
    $_.password = $Credential.GetNetworkCredential().Password
    $conn="{0}/{1}@{2}" -f $_.db_user, $_.password, $_.database_sdlc 
    $_.sqlplusArgs= @( "-L", $conn, "run.sql", $_.name, $_.logFile  )
  }
  $sqlFileInfo
}