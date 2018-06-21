<#
.SYNOPSIS

psake script for executing Pl/Sql files with sqlplus.exe

.DESCRIPTION

Executes sqlplus.exe over a collection of pl/sql files into the target SDLC Environment using Module OraclePlsqlInstaller

.EXAMPLE
@psake sqlplus.psake.ps1 -docs

Discover the available targets

.EXAMPLE
@set buildfile=sqlplus.psake.ps1
call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql');verbose=$false;whatif=$true;}" -parameters "@{sdlc='%sdlc%'}" %1
Runs the Pl/sql files in the current directory matching the pattern

.EXAMPLE
@set buildfile=sqlplus.psake.ps1
call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql');verbose=$true;whatif=$false;}" -parameters "@{sdlc='%sdlc%'}" %1
Runs the Pl/sql files in the current directory matching the pattern

.EXAMPLE
@set buildfile=sqlplus.psake.ps1
call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-8_]_*-*.sql');verbose=$false}" -parameters "@{sdlc='%sdlc%'}" %1
Runs the Pl/sql files in the current directory matching the pattern

.EXAMPLE
@set buildfile=sqlplus.psake.ps1
call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-8_]_*-*.sql');verbose=$false}" -parameters "@{sdlc='%sdlc%'}" ?
Runs the Pl/sql files in the current directory matching the pattern

.NOTES

Requires Modules

  psake
  OraclePlsqlInstaller

https://github.com/psake/psake

#>
#$VerbosePreference= 'Continue'
Framework '4.0'
Set-StrictMode -Version 4
$me = $MyInvocation.MyCommand.Definition
filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }

Import-Module OraclePlsqlInstaller

FormatTaskName "`r`n[------{0}------]`r`n"

task whatif -depends Clean, Init, Start-Logging, Show-Settings, Test-Connect, Accept, Whatif-sqlplus, Stop-Logging, Archive, Result -description ="Whatif No installation into database"

task default -depends install

Task install -depends Clean, Init, Start-Logging, Show-Settings, Test-Connect, Accept, Invoke-sqlplus, Stop-Logging, Archive, Result  -description "Install pl/sql files into database using sqlplus.exe"

properties {
  # sdlc must be set via -parameters
  $script:config_vars = @()
  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
    'cfg_sqlSpec'
     ,'IsoDateTimeStr'
     ,'JobDir'
     ,'JobName'
     ,'TempDir'
     ,'PoshLogPathAbs'
     ,'ArchiveZipPath'
     ,"ArchiveZipContentFileSpec"
     ,"verbose"
     ,"whatif"
     ,"sdlc"
     ,"zipExe"
     ,"sqlplusExe"
     ,"zipArgs"
  )
  $verbose = $false;
  $whatif = $false;
  $now = [System.DateTime]::Now
  write-verbose($("CurrentLocation={0}" -f $executionContext.SessionState.Path.CurrentLocation))

  write-host($VerbosePreference)
  Set-Variable -Name "JobName" -Description "Literal Path of the directory containing the psake file and associated sql files." -value $(Split-Path -Path $executionContext.SessionState.Path.CurrentLocation -Leaf)
  Set-Variable -Name "JobDir" -Description "Literal Path of the directory containing the psake file and associated sql files." -value $($executionContext.SessionState.Path.CurrentLocation)

  Set-Variable -Name "IsoDateTimeStr" -Description "Time and Date Stamp string" -Value $now.ToString("yyyy-MM-ddTHH-mm-ss")
  Set-Variable -Name "cfg_sqlSpec" -Description "Sql file wild cards spec" -value @('[0-9_][0-9_][0-9_]_*-*.sql', '[0-9_][0-9_][a-z]_*-*.sql')
  Set-Variable -Name "PoshLogPathAbs" -Description "Powershell logging file used by Start-Transcript" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc + "." + $IsoDateTimeStr + ".log"))
  Set-Variable -Name "TempDir" -Description "Temporary output files of the job." -value $($env:TEMP)
  Set-Variable -Name "ArchiveZipPath" -Description "ArchiveZipPath" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc + "." + $IsoDateTimeStr + ".zip"))
  Set-Variable -Name "ArchiveZipContentFileSpec" -Description "ArchiveZipContentFileSpec" -value $(join-path -Path $JobDir -ChildPath "*.log")
  $zipExe = "7z.exe"
  $zipArgs = @("-9j", $('"{0}"' -f $ArchiveZipPath), $('"{0}"' -f $ArchiveZipContentFileSpec)) #zip.exe
  $zipArgs = @("a", "-bt", "-bb2", $('"{0}"' -f $ArchiveZipPath), $('"{0}"' -f $ArchiveZipContentFileSpec)) #7z.exe
  $zipArgs = @("a", $('"{0}"' -f $ArchiveZipPath), $('"{0}"' -f $ArchiveZipContentFileSpec)) #7z.exe 9.38
  $sqlplusExe = "sqlplus.exe"
  #Variables shared between tasks
  $script:sqlCommands = @()
  $script:confirmation = $false;
}


task Show-Settings -description "Display the psake configuration properties variables" -depends init {
  Write-Verbose("Verbose is on")
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive| Format-Table -property name, value -autosize | Out-String -Width 2000| Out-Host
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive| format-list -Expand CoreOnly -property name, value | Out-String -Width 2000 | Out-Host
}


task Show-Passwords -description "Display the passwords in the credential files" -depends init {
  Write-Verbose("Verbose is on")
  $credFiles = $script:sqlCommands | sort -Property credentialFileName -Unique |% { $_.credentialFileName }
  @($credFiles).GetEnumerator() | Show-OracleSecret  | Out-String | write-host
}


task Show-SqlCommands -description "Display the command" -depends init {
  foreach ($i in $script:sqlCommands)
  {
    write-verbose $($i)
    write-host $sqlplusExe, $i.sqlplusArgs
  }
}


task Init -Description "Initialize the environment based on the properties" {
  Write-Verbose("Verbose is on")
  if (!($sdlc)) { throw "Variable SDLC not Set" }

  # VerbosePreference doesn't work under psake, must explicity define on the command line
  $(get-module OraclePlsqlInstaller).ExportedCommands.Keys | Out-String | write-verbose
  $initArgs = @{
    directory = $PSScriptRoot
    sqlSpec = $cfg_sqlSpec;
    logFileSuffix = $IsoDateTimeStr;
    netServiceNames = Set-SdlcConnections $sdlc.ToUpper();
    verbose = $verbose;
  }
  $script:sqlCommands = Get-SqlPlusCommands @initArgs
  $script:sqlCommands | Out-String | write-verbose
  "Done Initialization!"
}


task Test-Connect -depends Init -description "Test username and password connections"{
  $verbose = $true;
  $script:sqlCommands | Test-OracleConnections -sqlplusExe "sqlplus.exe" -verbose:$verbose -whatif:$whatif
}


task Clean -Description "Remove the previous generated files in the JobDir"  {
  Get-Childitem -LiteralPath $JobDir -Filter "*.log" | Where-Object {-Not $_.PSIsContainer} | Foreach-Object {Remove-Item $_.FullName -WhatIf:$whatif}
}


task Invoke-Sqlplus -depends Init -Description "Executes sqlplus.exe, Spool file specified as second parameter on command line" -PreCondition { $script:confirmation -eq $true } {
  New-OracleRunFixture
  @($script:sqlCommands).GetEnumerator() | %{
    Write-Host "Attempting : ", $sqlplusExe  $_.sqlplusArgs
    try
    {
      Start-ExeWithOutput -FilePath $sqlplusExe -ArgumentList $_.sqlplusArgs -verbose:$verbose -whatif:$whatif
    }
    catch [Exception] {
      Stop-Transcript -ErrorAction SilentlyContinue
      Start-ExeWithOutput -FilePath $zipExe -ArgumentList $zipArgs -verbose:$verbose -whatif:$whatif
      $errMsg = $_ | fl * -Force | Out-String
      Write-Host $errMsg
      throw
    }
  }
}


task Start-Logging -description "Log output" {
  Start-Transcript -Path $PoshLogPathAbs -verbose:$verbose -whatif:$whatif
}


task Stop-Logging{
  if ($whatif -ne $true) { Stop-Transcript }
}


task Archive -depends Init -Description "Archive the outputs in data directory to a datetime versioned zip file" {
  try
  {
    Start-ExeWithOutput -FilePath $zipExe -ArgumentList $zipArgs -verbose:$verbose -whatif:$whatif
  }
  catch [Exception] {
    $errMsg = $_ | fl * -Force | Out-String
    Write-Host $errMsg
    throw $_
  }
}

task Result -description "Success or Failure" {
  if ($script:confirmation -eq $false)
  {
    Write-Error -Message "Invoke-Sqlplus not executed" -Category InvalidResult
  }
}


task Show-SettingDetails -Description "Display detailed configuration variables, useful for debugging" {
 Get-Variable | format-table -Wrap | Out-Host
}

Task Get-DeliverableList -description "Create a list of files that should be in the zip file"{
  Get-BuildList -BuildPath "Specification.build"
}

task Accept -Description "Visual confirmation that we are hitting the correct configuration "-depends init{
  foreach ($i in $script:sqlCommands) {
    write-verbose $($i.fileName)
    write-host $sqlplusExe,$i.sqlplusArgs
  }
  $confirmation = read-Host -Prompt "Enter Y to Continue"
  if ($confirmation -eq 'Y')
  {
    $script:confirmation=$true
  }
}


task Pause {
  pause
}

task Whatif-Sqlplus -depends Init -Description "Displays sqlplus.exe, Spool file specified as second parameter on command line" {
  New-OracleRunFixture
  @($script:sqlCommands).GetEnumerator() | %{
    Write-Host "Attempting : ", $sqlplusExe  $_.sqlplusArgs
    try
    {
      Start-ExeWithOutput -FilePath $sqlplusExe -ArgumentList $_.sqlplusArgs -verbose:$verbose -whatif:$true
    }
    catch [Exception] {
      Stop-Transcript -ErrorAction SilentlyContinue
      Start-ExeWithOutput -FilePath $zipExe -ArgumentList $zipArgs -verbose:$verbose -whatif:$whatif
      $errMsg = $_ | fl * -Force | Out-String
      Write-Host $errMsg
      throw
    }
  }
}


task ? -Description "Helper to display task info" -depends help {
}


task help -Description "Helper to display task info" {
  Invoke-psake -buildfile $me -detaileddocs -nologo
  Invoke-psake -buildfile $me -docs -nologo
}