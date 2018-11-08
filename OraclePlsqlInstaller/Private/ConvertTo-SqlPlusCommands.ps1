function ConvertTo-SqlPlusCommands
<#
  .SYNOPSIS
    Converts the sql file names to sqlplus.exe Commands

    Returns an array of pl/sql command lines to executed with run.sql

  .DESCRIPTION
    Converts the sql file names matching $directory and $sqlSpec to sqlplus.exe Commands

  .PARAMETER directory
    Folder containing the pl/sql files
    Used to find the credential files and plsql file

  .PARAMETER sqlSpec
    Wild card specification of pl/sql files

  .PARAMETER logFileSuffix
    Suffix appended to the pl/sql file and used as the sqlplus.exe logfile.

  .PARAMETER netServiceNames
    A hash-table of Oracle Net Service Names

  .EXAMPLE
    010_views-pon.oms_op.sql

    Converts  to

    oms_op/oraPassword@pond.world @run.sql 010_views-pon.oms_op.sql 010_views-pon.oms_op.sql.log

    tnsName is "pon" in $netServiceNames["pon"]

  .NOTES
        [PSCustomObject]@{
          PSTypeName          Hash Table type = 'PSOracle.SqlPlusCmd'
          FileName            Pl/sql file name of the format 010_views-pon.oms_op.sql I.E. 010_views-<DatabaseIdentifier>.<OraUser>.sql
          OraUser             Oracle Username (SCHEMA). Translates username to actual value of $env:username
          Path                Absolute Path
          DatabaseIdentifier  The database type/model [PON,CNC,ONC]
          TnsName             Net Service Name E.G. pond.world
          LogFileName         Log file
          OraFQUserName       Oracle Fully Qualified User Name I.E. oms@pond.world rholliday@pond.world
          OraPassword
          IsInOraWallet       Is the password in the Oracle Wallet. Only used for username
          sqlplusArgs         Array of arguments to sqlplus.exe
          OraConnection       Oracle connect string to the database E.G. /@pond.world , oms/password@pond.world

  .EXAMPLE

FileName           : 140_pkg.PLANNED_OUTAGE-pon.oms.sql
OraUser            : oms
Path               : E:\Projects-Active\PSOraclePlSqlInstaller\OraclePlsqlInstaller\Specification\Data\140_pkg.PLANNED_OUTAGE-pon.oms.sql
DatabaseIdentifier : pon
TnsName            : POND.world
LogFileName        : 140_pkg.PLANNED_OUTAGE-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log
OraFQUserName      : oms@POND.world
OraPassword        : oms.password
IsInOraWallet      : False
sqlplusArgs        : {-L, "oms/oms.password@POND.world", @"run.sql", "140_pkg.PLANNED_OUTAGE-pon.oms.sql"...}
OraConnection      : "oms/oms.password@POND.world"

  .EXAMPLE
FileName           : ____entry_criteria-onc.username.sql
OraUser            : Russell
Path               : E:\Projects-Active\PSOraclePlSqlInstaller\OraclePlsqlInstaller\Specification\Data\____entry_criteria-onc.username.sql
DatabaseIdentifier : onc
TnsName            : ONCD.world
LogFileName        : ____entry_criteria-onc.username.sql.YYYY-MM-ddTHH-mm-ss.log
OraFQUserName      : Russell@ONCD.world
OraPassword        :
IsInOraWallet      : True
sqlplusArgs        : {-L, "/@ONCD.world", @"run.sql", "____entry_criteria-onc.username.sql"...}
OraConnection      : "/@ONCD.world"
#>
{
  [CmdletBinding()]
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
  $sqlPathSpec = $sqlSpec | % { $(Join-Path $directory $_) }
  write-verbose $("sqlPathSpec:{0}" -f $sqlPathSpec)
  foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
  {
    $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
  }
  #endregion Initialization code

  $sqlfiles = @(Resolve-Path -Path $sqlPathSpec -ErrorAction SilentlyContinue| sort-object -Unique)
  $sqlfiles.GetEnumerator() | Sort | % {
    write-verbose $("Processing {0}" -f $_) #TypeName: System.Management.Automation.PathInfo
    $fname = [System.IO.Path]::GetFileName($_)
    $index = [System.IO.Path]::GetFileNameWithoutExtension($fname).LastIndexOf('-')
    if ($index -gt -1)
    {
      $suffix = [System.IO.Path]::GetFileNameWithoutExtension($fname).substring($index + 1)
      $conn = $suffix -split "\."
      if ($conn.length -eq 2) 
      {
        $OraUser = if ($conn[1] -eq "username") { $env:username } else { $conn[1] }
        if (!($OraUser))
        {
          Write-Error -Message $("Oracle User name is null in : '{0}'" -f $fname) -Category SyntaxError
        }
        $DbName = $netServiceNames[$conn[0]]
        if (!($DbName))
        {
          Write-Error -Message $("Oracle DatabaseIdentifier '{0}' not found in '{1}' : {2}" -f $conn[0], $($netServiceNames.GetEnumerator().Name -join ", "), $fname) -Category SyntaxError
        }
        [PSCustomObject]@{
          PSTypeName          = 'PSOracle.SqlPlusCmd'
          FileName            = $fname
          OraUser             = $OraUser
          Path                = $_.ProviderPath
          DatabaseIdentifier  = $conn[0] # The database type/model
          TnsName             = $DbName # a Net Service Name
          LogFileName         = [System.IO.Path]::GetFileName($_) + "." + $logFileSuffix + ".log"
          OraFQUserName       = $("{0}@{1}" -f $OraUser, $DbName)
          OraPassword         = ""
          IsInOraWallet       = [bool]($conn[1] -eq "username")
          sqlplusArgs         = @()
          OraConnection       = $null
        }
      }
      else
      {
        Write-Error -Message $("Unparsable file name : '{0}'" -f $fname) -Category SyntaxError
      }
    }
    else
    {
      Write-Error -Message $("Unparsable file name : '{0}'" -f $fname) -Category SyntaxError
    }
  }
}