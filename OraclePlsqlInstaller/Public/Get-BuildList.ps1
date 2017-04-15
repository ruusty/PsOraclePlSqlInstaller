function Get-BuildList
<#
  .SYNOPSIS
    Gets the paths of pl/sql executed by the top pl/sql *.sql files
  
  .DESCRIPTION
    Extracts the file names of SQL*Plus script files from the top pl/sql *.sql files.
    Creates a *.lis file containing file names used to create a zip.
    
    SQL*Plus script files are identified by the @ or @@ symbol at the start of the line.
    
    E.G.
    
    @@ src\OMS_OP\sql_views\OMS_OP.OP_PLANNED_NMIS.[sql][pk?]
  
  .PARAMETER Path
    Regular expression matching top pl/sql *.sql files
  
  .PARAMETER BuildPath
    Nant build file name. The name of the lis files is same as Nant build file name
  
  .PARAMETER prolog
    Prolog files names of static files
  
  .PARAMETER logsuffix
    Creates files names with these suffixes and the file name of the Nant build file.

  .EXAMPLE
    Get-BuildList -verbose
  
  .NOTES
    Validates the files exist.  Throws an error if any files do not exist
    
    Builds the lis file used by the Nant build file to create the zip deliverable file
#>
{
  [CmdletBinding(DefaultParameterSetName = 'Path')]
  param
  (
    [Parameter(Position = 1)]
    [String[]]$Path = $("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql"),
    [string]$BuildPath = $(Resolve-Path -Path $(Join-Path $PWD "*.build") -Relative | sort | Select-Object -First 1),
    [string[]]$prolog = @('README.md','README.html', 'install.bat', 'sql.default.ps1' ),
    [string[]]$logsuffix = @(".Build.Number", ".git_history.log")
  )
  #region Initialization code
  "PSBoundParameters",$PSBoundParameters.GetEnumerator() | ForEach {
    $_
  } | Out-String | write-verbose
  #The list file has the same name as the build file
  $ProjectLisPath = [System.IO.Path]::ChangeExtension($BuildPath, ".lis")
  $BuildPathNoExt = [System.IO.Path]::GetFileNameWithoutExtension($BuildPath)
#write the parameters
  foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
  {
    $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
  }
   $ErrorActionPreference = "Stop"
   #endregion Initialization code
  
  function recurseSqlFiles
  (
    [string]$sqlfname
  )
  {
    write-debug($sqlfname.getType().fullname)
    Write-verbose ("recurseSqlFiles In:{0}" -f $sqlfname)
    @($sqlfname)
    Get-content $_ | Select-String -Pattern "^\s*@{1,2} *(?<fname2>[0-9A-Za-z-_\\/\.\$]+[sql|pkb|pks])" | Select -Expand Matches | foreach { $_.Groups["fname2"] } | Select -Expand Value | Skip-Null | %{
      if (Test-Path -Path $_)
      {
        Write-verbose ("{0} type {1}" -f $_, $_.GetType())
        #Write-verbose ("recurseSqlFiles2:{0}" -f $_)
        if ($resultoutputfiles -notcontains $_)
        {
          Write-verbose ("Added:$_")
          @($_);
        }
      }
      else
      {
        throw [System.IO.FileNotFoundException] "File not found : $_"
      }
    }
  }
  
  filter Skip-Null { $_ | ?{ $_ -ne $null } }
  
  # yeah! the cmdlet supports wildcards
  switch ($PsCmdlet.ParameterSetName)
  {
    "Path"         { $ResolveArgs = @{ Path = $Path }; break }
  }
  
  $resultoutputfiles = @();
  $resultoutputfiles = foreach ($i in $logsuffix)
  {
    ("{0}{1}" -f $BuildPathNoExt , $i)
  }
  $resultoutputfiles += $prolog
  
  
  Resolve-Path -ErrorAction "Stop" @ResolveArgs | get-item | where-object { $_.length -gt 0 } | sort-object Name | %   {
    #Just want the name
    write-verbose("Name:{0}" -f $_.Name)
    $resultoutputfiles += @(recurseSqlFiles -ErrorAction "Stop" $_.Name)
  }
  $resultoutputfiles | set-Content -Path $ProjectLisPath
}