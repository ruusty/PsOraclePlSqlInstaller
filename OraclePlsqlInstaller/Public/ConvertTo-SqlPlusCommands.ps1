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
    password is encrypted in the file "oms_op"+ "@" + $netServiceNames["pon"]+".credential"

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
  
  $sqlfiles = @(Resolve-Path -Path $sqlPathSpec | sort-object -Unique)
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
          $oraUser = $conn[1]; # The oracle schema to execute the file;
          if ($oraUser -eq "username")
          {
            $oraUser = $env:username
        }
        $credFname = $("{0}@{1}.credential" -f $oraUser, $netServiceNames[$conn[0]])
        [PSCustomObject]@{
            PSTypeName='PSOracle.SqlPlusCmd'
            fileName = $fname
            oraUser = $oraUser
            path = $_.ProviderPath
            databaseIdentifier = $conn[0] # The database type/model 
            tnsName          = $netServiceNames[$conn[0]] # a Net Service Name
            logFileName = [System.IO.Path]::GetFileName($_) + "." + $logFileSuffix + ".log"
            credentialFileName = $(join-path $directory $credFname)
            oraPassword = ""
            sqlplusArgs = @()
          }
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