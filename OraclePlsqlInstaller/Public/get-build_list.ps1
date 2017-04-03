<#
  .SYNOPSIS
    Gets the paths of all pl/sql files used in a psake sql runner package.

  .DESCRIPTION
    Extracts the file names of SQL*Plus script files from the selected pl/sql files.

    SQL*Plus script files are identified by the @ or @@ symbol at the start of the line.

    E.G.


    @@ src\OMS_OP\sql_views\OMS_OP.OP_PLANNED_NMIS.[sql][pk?]

  .PARAMETER Path
    Regular expression matching sql file names

  .PARAMETER BuildPathNoExt
    File name (no extension ) of the output file

  .EXAMPLE
     .\get-build_list.ps1

  .NOTES
    Validates the files exist.  Throws an error if any files do not exist

    Builds the lis file used by the Nant build file to create the zip deliverable file
#>
[CmdletBinding(DefaultParameterSetName = 'Path')]
param
(
  [Parameter(Position = 1)]
  [String[]]$Path = $("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql"),
  [Parameter(Position = 2)]
  [Alias('ProjectName', 'PSPath')]
  [string]$BuildPathNoExt = $(Resolve-Path -Path *.build | sort | Select-Object -First 1 | %{ [System.IO.Path]::ChangeExtension($(Split-Path $_ -Leaf), "") } | %{ $_.TrimEnd('.') })
)
$PSBoundParameters.GetEnumerator() | ForEach {
  Write-Verbose $($_ | Out-String)
}
$ErrorActionPreference="Stop"
Write-Verbose $BuildPathNoExt
$Path | Out-String |Write-Verbose


function recurseSqlFiles
(
[string]$sqlfname
)
{
  write-debug($sqlfname.getType().fullname)
  Write-verbose ("recurseSqlFiles In:{0}" -f $sqlfname)
  @($sqlfname)
  Get-content $_  | Select-String -Pattern  "^\s*@{1,2} *(?<fname2>[0-9A-Za-z-_\\/\.\$]+[sql|pkb|pks])"  | Select -Expand Matches | foreach {$_.Groups["fname2"]} | Select -Expand Value  | Skip-Null | %{
     if (Test-Path -Path $_) {
        Write-verbose ("{0} type {1}" -f $_, $_.GetType())
        #Write-verbose ("recurseSqlFiles2:{0}" -f $_)
     if ( $resultoutputfiles -notcontains $_ ){
        Write-verbose ("Added:$_")
        @($_);
        }
     }else {
        throw "File not found : $_"
     }
  }
}

filter Skip-Null { $_|?{ $_ -ne $null } }

# yeah! the cmdlet supports wildcards
switch ($PsCmdlet.ParameterSetName)
{
"Path"         { $ResolveArgs = @{Path=$Path} ; break}
}



$prolog = @'
default.ps1
install.bat
README.md
README.html
run.sql
*.config
show-OraSecret.ps1

'@
$resultoutputfiles = @();
$resultoutputfiles = foreach ($i in (".Build.Number", ".git_revision.log", ".history.log"))
{
  ($BuildPathNoExt + $i)
}
$resultoutputfiles += $prolog


  Resolve-Path -ErrorAction "Stop" @ResolveArgs  | get-item  | where-object { $_.length -gt 0 } | sort-object Name | %   {
  #Just want the name
  write-verbose("Name:{0}" -f $_.Name)
  $resultoutputfiles += @(recurseSqlFiles -ErrorAction "Stop" $_.Name)
}

$ProjectLisPath = $BuildPathNoExt + ".lis"
$resultoutputfiles | set-Content -Path $(Join-Path $PSScriptRoot $ProjectLisPath)

