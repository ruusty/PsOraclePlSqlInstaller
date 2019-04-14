<#
  .SYNOPSIS
    psake script for executing Pl/Sql files with sqlplus.exe

  .DESCRIPTION
    Executes sqlplus.exe over a collection of pl/sql files into the target SDLC Environment using Module OraclePlsqlInstaller

  .EXAMPLE
    Invoke-psake  sqlplus.psakefile.ps1 -docs

   Discover the available targets

  .EXAMPLE
    Invoke-psake -nologo -buildFile 'sqlplus.psakefile.ps1' -parameters "@{VerbosePreference='SilentlyContinue';DebugPreference='SilentlyContinue';sdlc='%sdlc%';JobName='%JobName%'}" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql')}" -taskList $tasklist
    Runs the Pl/sql files in the current directory matching the pattern


  .EXAMPLE
    Invoke-psake -nologo -buildFile 'sqlplus.psakefile.ps1' -parameters $params -properties $props -taskList $tasklist

  .NOTES

    Requires Modules
      psake
      OraclePlsqlInstaller
      BetterCredentials
#>
Framework '4.0'
Set-StrictMode -Version 4
$me = $MyInvocation.MyCommand.Definition
filter Skip-Empty { $_ | Where-Object{ $_ -ne $null -and $_ } }

Import-Module OraclePlsqlInstaller

FormatTaskName "`r`n[------{0}------]`r`n"

Task default -depends install

Task install -depends Clean, Init, Start-Logging, Show-Settings, Test-Connect, Accept, Invoke-sqlplus, Validate-OraLogs, Stop-Logging, Archive, ExitStatus  -description "Execute pl/sql files into database using sqlplus.exe"

Properties {
  # sdlc must be set via -parameters
  Assert -conditionToCheck { $JobName -ne $null } -failureMessage "$JobName must be set"
  Assert -conditionToCheck { $SDLC -ne $null } -failureMessage "$SDLC must be set"
  Assert -conditionToCheck { $SrrCredential -ne $null } -failureMessage "SRR oms_user credential must be defined."
  $script:config_vars = @()
  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
    'cfg_sqlSpec'
    'IsoDateTimeStr'
    'JobDir'
    'JobName'
    'TempDir'
    'PoshLogPathAbs'
    'ArchiveZipPath'
    "ArchiveZipContentFileSpec"
    "verbose"
    "sdlc"
    "zipExe"
    "sqlplusExe"
    "zipArgs"
    "WhatIfPreference"
    "VerbosePreference"
    "force"
  )
  $IsVerbose = ($VerbosePreference -eq 'Continue');
  $now = [System.DateTime]::Now
  write-verbose($("CurrentLocation={0}" -f $executionContext.SessionState.Path.CurrentLocation))

  write-host($VerbosePreference)
  Set-Variable -Name "JobDir" -Description "Literal Path of the directory containing the psake file and associated sql files." -value $($executionContext.SessionState.Path.CurrentLocation) -What:$false

  Set-Variable -Name "IsoDateTimeStr" -Description "Time and Date Stamp string" -Value $now.ToString("yyyy-MM-ddTHH-mm-ss") -What:$false
  Set-Variable -Name "cfg_sqlSpec" -Description "Sql file wild cards spec" -value @('[0-9_][0-9_][0-9_]_*-*.sql', '[0-9_][0-9_][a-z]_*-*.sql') -What:$false
  Set-Variable -Name "PoshLogPathAbs" -Description "Powershell logging file used by Start-Transcript" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc + "." + $IsoDateTimeStr + ".log")) -What:$false
  Set-Variable -Name "TempDir" -Description "Temporary output files of the job." -value $($env:TEMP) -What:$false
  Set-Variable -Name "ArchiveZipPath" -Description "ArchiveZipPath" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc + "." + $IsoDateTimeStr + ".zip")) -What:$false
  Set-Variable -Name "ArchiveZipContentFileSpec" -Description "ArchiveZipContentFileSpec" -value $(join-path -Path $JobDir -ChildPath "*.log") -What:$false
  $zipExe = "7z.exe"
  $zipArgs = @("a", "-bt", "-bb2", $('"{0}"' -f $ArchiveZipPath), $('"{0}"' -f $ArchiveZipContentFileSpec)) #7z.exe
  $sqlplusExe = "sqlplus.exe"
  #Variables shared between tasks
  $script:sqlCommands = @()
  $script:confirmation = $false;
  [boolean]$script:isOraErrors = $false
  $force=$false
  #sqlplus.exe user/pwd@connect_identifier @run.sql file_to_run.sql file_to_run.sql.log
  $OracleRunFixturePath = join-path -path $PSScriptRoot -ChildPath "run.sql"
}


Task Show-Settings -description "Display the psake configuration properties variables"  {
  Write-Verbose("Verbose is on")
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive| Format-Table -property name, value -autosize | Out-String -Width 2000| Out-Host
  #Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive| format-list -Expand CoreOnly -property name, value | Out-String -Width 2000 | Out-Host
}


Task Show-Passwords -description "Display the passwords" -depends init {
    OraclePlsqlInstaller\Show-OracleCredentials -sdlc $sdlc
}


Task Show-SqlCommands -description "Display the command" -depends init {
  foreach ($i in $script:sqlCommands)
  {
    write-verbose $($i)
    write-host $sqlplusExe, $i.sqlplusArgs
  }
}


Task Init -Description "Initialize the environment based on the properties" {
  Write-Verbose("Verbose is on")

  # VerbosePreference doesn't work under psake, must explicity define on the command line
  #$(get-module OraclePlsqlInstaller).ExportedCommands.Keys | Out-String | write-verbose
  $initArgs = @{
    directory = $PSScriptRoot
    sqlSpec = $cfg_sqlSpec;
    logFileSuffix = $IsoDateTimeStr;
    netServiceNames = OraclePlsqlInstaller\Set-SdlcConnections -sdlc $sdlc;
    verbose     = $IsVerbose;
  }
  $initArgs | Out-String | write-verbose

  $script:sqlCommands = OraclePlsqlInstaller\Get-SqlPlusCommands @initArgs
  $script:sqlCommands | Out-String | write-verbose
  Write-Host "Done Initialization!"
}


Task Test-Connect -depends Init -description "Test username and password connections"{
  $script:sqlCommands | OraclePlsqlInstaller\Test-OracleConnections -sqlplusExe "sqlplus.exe" -verbose:$IsVerbose -whatif:$false
}


Task Clean -Description "Remove the previous generated files in the JobDir"  {
  Get-Childitem -LiteralPath $JobDir -Filter "*.log" | Where-Object {-Not $_.PSIsContainer} | Foreach-Object {Remove-Item $_.FullName -WhatIf:$WhatIfPreference}
}


Task New-RunFixture -Description "Create the run.sql" {
  OraclePlsqlInstaller\New-OracleRunFixture
  #Add configuration defines
  $runSql = get-content -path $OracleRunFixturePath
  $newSql = foreach ($line in $runSql) {
    if ($line -eq 'define'){
      $("define SRRPassword={0}" -f $SrrCredential.GetNetworkCredential().Password)
    }
    $line
  }
  $newSql | set-content -path $OracleRunFixturePath
}


Task Invoke-Sqlplus -depends Init,New-RunFixture -Description "Executes sqlplus.exe, Spool file specified as second parameter on command line" -PreCondition { ($script:confirmation -eq $true) } {
  @($script:sqlCommands).GetEnumerator() | ForEach-Object{
    Write-Host "Attempting : ", $sqlplusExe  $_.sqlplusArgs
    try
    {
      OraclePlsqlInstaller\Start-ExeWithOutput -FilePath $sqlplusExe -ArgumentList $_.sqlplusArgs -verbose:$IsVerbose -whatif:$WhatIfPreference
    }
    catch [Exception] {
      $errMsg = $_ | Format-List * -Force | Out-String
      Stop-Transcript -ErrorAction SilentlyContinue
      OraclePlsqlInstaller\Start-ExeWithOutput -FilePath $zipExe -ArgumentList $zipArgs -verbose:$IsVerbose -whatif:$WhatIfPreference
      Write-Host $errMsg
      throw
    }
  }
  remove-item -path $OracleRunFixturePath -ErrorAction SilentlyContinue
}


Task Start-Logging -description "Log output" {
  Start-Transcript -Path $PoshLogPathAbs -verbose:$IsVerbose -whatif:$WhatIfPreference
}


Task Stop-Logging -description "Stop the logging" {
    $match = '/([^@]+)'
    if ($WhatIfPreference -ne $true) {
        Stop-Transcript -ErrorAction SilentlyContinue
        if (Test-Path -path $PoshLogPathAbs) {
            Move-Item -Path $PoshLogPathAbs -Destination $bak
            Get-Content -Path $bak | ForEach-Object { $_ -creplace $match , '/__password__' } | Set-Content -Path $PoshLogPathAbs
            Remove-Item -Path $bak -Force
        }
    }
}


Task Archive -depends Init -Description "Archive the outputs in data directory to a datetime versioned zip file" {
  try
  {
    OraclePlsqlInstaller\Start-ExeWithOutput -FilePath $zipExe -ArgumentList $zipArgs -verbose:$IsVerbose -whatif:$WhatIfPreference
  }
  catch [Exception] {
    $errMsg = $_ | Format-List * -Force | Out-String
    Write-Host $errMsg
    throw $_
  }
}


Task ExitStatus -description "Success or Failure"  {
  if ($script:confirmation -eq $false)
  {
    Write-Host "Invoke-Sqlplus not executed"
  }
  else
  {
    if ($script:isOraErrors)
    {
      Write-Error -Message "Oracle errors found in Log file" -Category InvalidOperation
    }
    else
    {
      Write-Host "SUCCESS"
    }
  }
}


Task Validate-OraLogs -description "Check for Oracle Errors in log files " -PreCondition { ($script:confirmation -eq $true) -and (!$WhatIfPreference) }  {
  @($script:sqlCommands).GetEnumerator() | %{
    $logPath = Join-Path -path $PSScriptRoot -childpath $_.logFileName
    Write-Verbose -message $('Attempting : Test for Oracle Errors in {0}' -f $logPath)
    #There should be a log file
    if (!(Test-Path -Path $logPath ))
    {
      $script:isOraErrors =$true
      Write-Warning -Message $('{0} not found' -f $logPath)
      return
    }
    $rv = Select-String -Pattern '^ORA-[0-9]+','^SP2-[0-9]+' -Path $logPath
    if ($rv)
    {
      $script:isOraErrors = $true
      $rv | out-string | Write-Warning
    }
  }
  if ($script:isOraErrors)
  {
    Write-Warning "Oracle Errors found in pl/sql log files"
  }
}


Task Show-SettingDetails -Description "Display detailed configuration variables, useful for debugging" {
 Get-Variable | format-table -Wrap | Out-Host
}


Task Get-DeliverableList -description "Create a list of files that should be in the zip file" {
  $ProjectName = [System.IO.Path]::GetFileName($PSScriptRoot)
  $ProjPackageListPath = Join-Path $PSScriptRoot "${ProjectName}.lis"
  OraclePlsqlInstaller\Get-BuildList  | Sort-Object -Unique | Set-Content -Path $ProjPackageListPath
}


Task Accept -Description "Visual confirmation that we are hitting the correct configuration "-depends init{
  foreach ($i in $script:sqlCommands) {
    write-verbose $($i.fileName)
    write-host $sqlplusExe,$i.sqlplusArgs
  }
  if ($force){
    $script:confirmation=$true
  }else{
    $confirmation = read-Host -Prompt "Enter Y to Continue"
    if ($confirmation -eq 'Y' )
    {
      $script:confirmation=$true
    }
  }
}


task Pause {
  pause
}


Task help -Description "Helper to display task info" -alias '?' {
  Invoke-psake -buildfile $me -detaileddocs -nologo
  Invoke-psake -buildfile $me -docs -nologo
}
