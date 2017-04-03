<#
  .SYNOPSIS
    Parses the sql file names and extracts the database service and Oracle account(schema) encoded in the filename
    
    Returns an array of pl/sql command lines to executed with run.sql
  
  .DESCRIPTION
    A detailed description of the parseSqlFilename function.
  
  .PARAMETER directory
    A description of the directory parameter.
  
  .PARAMETER sqlSpec
    A description of the sqlSpec parameter.
  
  .PARAMETER sqlFilenames
    A description of the sqlFilenames parameter.
  
  .PARAMETER l_sdlc_svc_name
    A description of the l_sdlc_svc_name parameter.
  
  .EXAMPLE
    010_views-pon.oms_op.sql
    
    parses to
    
    oms_op/pwd@tns @ sql_runner.sql 010_views-pon.oms_op.sql 010_views-pon.oms_op.sql.log
    
    tns is pon in $cfg_local["pon"] from SDLC.config
    
    password is encrypted in the file "oms_op"+ "@" + $cfg_local["pon"]+".credential"
    
    $db_user + "@" + $cfg_local[$db] + ".credential"
    
    These are configured in the SDLC.config file where SDLC domain (PROD,UAT,TEST,DEV)
  
  .NOTES
    for a sqlSpec get the files
#>
function Parse-SqlFilenames
{
  [CmdletBinding()]
  param
  (
    [Parameter(Position = 1)]
    [string]$directory = $PSScriptRoot,
    [Parameter(Position = 2)]
    [string[]]$sqlSpec = @("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql"),
    $isoTimeStamp = ".YYYY-MM-ddTHH-mm-ss",
    $local_service = @{ pon = "POND.world"; onc = "ONCD.world" }
  )
  
  BEGIN
  {
    $PSBoundParameters.GetEnumerator() | % {
      Write-Verbose($("{0} : {1} " -f $_.key, $_.value))
    }
    Write-Verbose $directory
    $sqlSpec | Out-String | write-verbose
    $sqlDetails = @()
  }
  
  PROCESS
  {
    $sqlPathSpec = $sqlSpec | % { $(Join-Path $directory $_) }
    $sqlPathSpec | Out-String | write-verbose
    $sqlfiles = Resolve-Path -Path $sqlPathSpec | sort-object -Unique
    $sqlfiles | Out-String | write-verbose
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
          $db_user = $conn[1]; # The oracle schema;
          if ($db_user -eq "username")
            {
              $db_user = $env:username
            }
          $details = @{
            name = $fname
            db_user = $db_user
            path = $_.ProviderPath
            database = $conn[0] # The database prefix
            logFile = [System.IO.Path]::GetFileName($_) + $isoTimeStamp + ".log"
            database_sdlc = $local_service[$conn[0]]
            pwdFname = $db_user + "@" + $local_service[$conn[0]] + ".credential"
            password = ""
            sqlplusArgs =@()
          }
          $sqlDetails += @($details)
        }
        else
        {
          throw $("Unparsable file name '{0}'" -f $_)
        }
      }
      else
      {
        throw $("Unparsable file name '{0}'" -f $_)
      }
    }
  }
  END
  {
    $sqlDetails | Out-String | write-verbose
    $sqlDetails
  }
}