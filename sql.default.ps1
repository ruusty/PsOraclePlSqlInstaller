<#
.SYNOPSIS

This is a psake script

Executes Pl/Sql files with sqlplus.exe

.DESCRIPTION

Executes sqlplus.exe over a collection of pl/sql files into the target SDLC Environment

Manage the encryption a decryption of Oracle SDLC passwords

.EXAMPLE

Discover the available targets

@psake -docs

.EXAMPLE

Test the configuration and connection to the database schemas required to apply the scripts (no changes)

install dev TestConnect 

.EXAMPLE

install dev

Runs the Pl/sql files in the current directory matching the pattern

("[0-9_][0-9_][0-9_]_*-*.sql","[0-9_][0-9_][a-z]_*-*.sql")

into DEV SDLC

Sample filename matching this pattern

  ___entry_criteria-onc.username.sql
  021a_table_status_data-onc.oproc.sql
  021c_views-onc.oproc.sql
  022_table_UnplannedCust-onc.oproc.sql

.EXAMPLE

install dev run

.NOTES

Requires psake

https://github.com/psake/psake

#>
Framework '4.0'

filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }

. $(Join-Path $PSScriptRoot "get-commandLines.ps1" )
. $(Join-Path $PSScriptRoot "Parse-SqlFilenames.ps1")
. $(Join-Path $PSScriptRoot "Set-SdlcConnections.ps1")
. $(Join-Path $PSScriptRoot "Test-OracleConnection.ps1")
. $(Join-Path $PSScriptRoot "Get-OracleSchemaPasswords")
. $(Join-Path $PSScriptRoot "Show-SqlFileInfo")

FormatTaskName "[-----{0}------]"

task unit-test -depends Init, Clean, TestConnect, ShowSettings, ShowSettingsDetails, Accept

task default -depends run

Task run -depends Init, Clean, TestConnect, ShowSettings, Accept, Invoke-sqlplus, Archive -description "Do it"




properties {
  $script:config_vars=@()
  Set-Variable -Name "JobDir"          -Description "Literal Path of the directory containing the ControlM batch file and associated sql files." -value $(Resolve-Path .)
  write-verbose("sdlc_environment=$sdlc_environment")
  write-verbose("JobName=$JobName")

#  Set-Variable -Name "base_dir" -Description "Same as JobDir except but by `$executionContext.SessionState.Path.CurrentLocation " -value $($executionContext.SessionState.Path.CurrentLocation)

  $x=[System.DateTime]::Now

  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
     'sdlc_environment'
    ,'cfg_sqlSpec'
    ,'IsoDateTimeStr'
    ,'JobDir'
    ,'JobName'
    ,'TempDir'
    ,'VerbosePreference'
     ,'PoshLogPathAbs'
     ,'ArchiveZipPath'
    ,"ArchiveZipContentFileSpec"
  )
  
  Set-Variable -Name "IsoDateTimeStr"   -Description "Time and Date Stamp string" -Value $([string]::Format('{0}-{1:d2}-{2:d2}T{3:d2}-{4:d2}-{5:d2}',$x.year,$x.month,$x.day,$x.hour,$x.minute,$x.second))

  Set-Variable -Name "sdlc_environment" -Description "System Development Life Cycle Environment" -value $sdlc_environment
  Set-Variable -Name "cfg_sqlSpec"      -Description "Sql file wild cards spec" -value $($cfg_sqlSpec)
  Set-Variable -Name "PoshLogPathAbs"   -Description "Powershell logging file used by Start-Transcript" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc_environment + "." + $IsoDateTimeStr + ".log"  ))
  Set-Variable -Name "TempDir"          -Description "Temporary output files of the job." -value $($env:TEMP)
  Set-Variable -Name "ArchiveZipPath"   -Description "ArchiveZipPath" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $sdlc_environment + "." + $IsoDateTimeStr + ".zip"))
  Set-Variable -Name "ArchiveZipContentFileSpec" -Description "ArchiveZipContentFileSpec" -value  $(join-path -Path $JobDir  -ChildPath "*.log")

  $cfg_sqlSpec = @('[0-9_][0-9_][0-9_]_*-*.sql','[0-9_][0-9_][a-z]_*-*.sql')
  $script:sqlFileInfo = @()
  
}

task ShowSettings -Description "Display the psake configuration variables properties" {
  #Start-Transcript -Path $PoshLogPathAbs
  #$script:sqlFileInfo | Out-String | write-verbose
  $ErrorActionPreference = "Continue"
  $script:sqlFileInfo.GetEnumerator() | Sort-Object Name | format-table -auto | Out-Host
  
  Get-Variable -name $script:config_vars | Format-Table -property name, value -autosize | Out-Host
  
  #$script:config_vars | get-variable | sort-object -unique -property "Name" | Select-Object Name,value,Description, options | Format-table @{n='Name';e={$_.Name};align='left';w=30},@{n='Value';e={$_.Value};align='left';w=50},Description -wrap | Out-String
  #  $script:config_vars | get-variable | sort-object -unique -property "Name" | Select-Object Name,value,Description, options | Format-list | Out-Host
  #  @($script:sqlfiles).GetEnumerator() | Sort-Object | format-table -auto | Out-Host
  #  Get-Variable -name @("sdlc*","cfg_*") | Format-Table -property name, value -autosize | Out-Host
  #  $cfg_local.GetEnumerator() | Sort-Object Name | format-table -auto | Out-Host
  #  Write-Host "Credential Files`r`n----------------"
  #  $script:credFiles | Out-String | Out-Host
  #  Write-Host "SQL Plus`r`n--------"
  #  $script:cmdlines | Out-String | Out-Host
  
  
}



task Init -Description "Initialize the environment based on the properties" {
  $initArgs = @{
    directory = $PSScriptRoot;
    sqlSpec = $cfg_sqlSpec;
    isoTimeStamp = $IsoDateTimeStr;
    local_service = Set-SdlcConnections $sdlc_environment;
  }
  $script:sqlFileInfo = $(Parse-SqlFilenames @initArgs)
  Get-OracleSchemaPasswords $script:sqlFileInfo
  $script:sqlFileInfo = Get-CommandLines $script:sqlFileInfo
  "Done Initialization!"
}

task show -depends init -description "Displays the xxx" {
  Show-SqlFileInfo $script:sqlFileInfo
}


task TestConnect -depends Init -description "Test username and password connections"{
  #Expected format of cmdlines
  Test-OracleConnections $script:sqlFileInfo
}


task clean -Description "Remove the previous generated files in the JobDir"  {
  Get-Childitem -LiteralPath $JobDir -Filter "*.log" | Where-Object {-Not $_.PSIsContainer} | Foreach-Object {Remove-Item $_.FullName}
}


task Invoke-Sqlplus -depends Init, Accept -Description "Executes sqlplus.exe, Spool file specified as second parameter on command line"  {

  try {
        @($script:sqlFileInfo).GetEnumerator() | %{
          write-host("sqlplus.exe -L {0}" -f $_  )
          #exec {sqlplus.exe -L $_ }
      }
    }
  catch [Exception] {
    write-verbose ( "`$LastExitCode:$LastExitCode")
    $errMsg = $_ | fl * -Force | Out-String
    Write-Host $errMsg
    write-Host "`$LastExitCode=$LastExitCode`r`n"
    Write-Host zip.exe -9j ""$ArchiveZipPath"" ""$ArchiveZipContentFileSpec""
       exec {  zip.exe -9j ""$ArchiveZipPath"" ""$ArchiveZipContentFileSpec"" }
    throw
  }
}


task Archive -depends Init -Description "Archive the outputs in data directory to a datetime versioned zip file in the Archive sub-directory" {
  try {
      Write-Host zip.exe -9j ""$ArchiveZipPath"" ""$ArchiveZipContentFileSpec""
      exec {  zip.exe -9j ""$ArchiveZipPath"" ""$ArchiveZipContentFileSpec"" }
  }
  catch [Exception] {
    write-verbose ( "`$LastExitCode:$LastExitCode")
    $errMsg = $_ | fl * -Force | Out-String
    Write-Host $errMsg
    write-Host "`$LastExitCode=$LastExitCode`r`n"
    throw
  }
}


task ShowSettingsDetails -Description "Display detailed configuration variables, useful for debugging" {
 Get-Variable | format-table -Wrap | Out-Host
}




task Accept -Description "Visual confirmation that we are hitting the correct configuration "{
  $confirmation = read-Host -Prompt "Press Return to Continue"
}

