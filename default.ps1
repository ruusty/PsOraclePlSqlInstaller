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




<#
  .SYNOPSIS
    Parses the sql file names and extracts the database service and Oracle account(schema) encoded in the filename
    
    Returns an array of pl/sql command lines to executed with run.sql
  
  .DESCRIPTION
    A detailed description of the parseSqlFilename function.
  
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
function parseSqlFilename
{
  [CmdletBinding()]
   param
  (
    $sqlSpec = @("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql")
  )
  
  $ErrorActionPreference = 'Stop'
  trap { "parseSqlFilename failed"; break }
  $sqlfiles = Resolve-Path -Path @($cfg_sqlSpec) | sort-object -Unique
  
  $sqlfiles.GetEnumerator() | Sort | % {
    write-verbose $("Processing {0}" -f $_)
    $fname = [System.IO.Path]::GetFileName($_)
    $index = [System.IO.Path]::GetFileNameWithoutExtension($fname).LastIndexOf('-')
    if ($index -gt -1)
    {
      $user = [System.IO.Path]::GetFileNameWithoutExtension($fname).substring($index + 1)
      $sql[$fname] = $user;
      $conn = $user -split "\."
      if ($conn.length -eq 1)
      {
        # The file name does not have the database encoded.
        $db_user = $cfg_ora_user # From the config file
        $db = $cfg_local.keys[0] # Use single value of hash array in the config file
      }
      elseif ($conn.length -eq 2)
      {
        $db = $conn[0] # The database prefix
        $db_user = $conn[1]; # The oracle schema
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
    
    if ($l_sdlc_svc_name -notcontains $cfg_local[$db])
    {
      throw "Incorrect configuration for {0} : {1} `!= {2}" -f $sdlc_environment, $l_sdlc_svc_name, $cfg_local[$db]
    }
    if ($db_user -eq "username")
    {
      $db_user = $env:username
    }
    
    $pwdFname = $db_user + "@" + $cfg_local[$db] + ".credential"
    
    if (Test-Path "..\$pwdFname") { $pwdFname = "..\$pwdFname" }
    if ($script:credFiles -notcontains $pwdFname) { $script:credFiles += $pwdFname }
    if (Test-Path $pwdFname)
    {
      Write-Verbose "Getting credentials from $pwdFname"
    }
    else
    {
      $name = [System.IO.Path]::GetFileNameWithoutExtension($pwdFname)
      Write-Verbose $("Creating credentials file {0}" -f $name)
      #parse out the connection_identifier string
      $connect_identifier = "notset"
      if ($name -match '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)')
      {
        $user = $matches[1]
        $connect_identifier = $matches[2]
      }
      Write-verbose  $("{0}/{1}@{2}" -f $user, "", $connect_identifier)
      #Prompt for the credentials and save
      [pscredential]$Credential = $(Get-Credential -UserName $user -Message "Enter Oracle $user Password for $connect_identifier")
      if (!$Credential) { exit }
      $credPath = Join-Path -Path $PSScriptRoot -ChildPath $($user + "`@$connect_identifier.credential")
      $Credential | Export-CliXml $credPath
    }
    $Credential = Import-Clixml $pwdFname -ErrorAction Stop
    $user = $Credential.GetNetworkCredential().Username
    $pwd = $Credential.GetNetworkCredential().Password
    
    $SqlLogPath = [System.IO.Path]::GetFileName($(join-path -Path $JobDir -ChildPath $($fname + "." + $sdlc_environment + "." + $IsoDateTimeStr + ".log")));
    if ($env:username -eq $db_user -and $pwd -eq $null)
    {
      # Run using Oracle Wallet
      #                 /
      $cmdLine = "`"{0}{1}{2}`@{3}`"" -f "", "/", "$pwd", $cfg_local[$db]
      $cmdLine = $cmdLine.PadRight(30)
      $cmdLine += " `@`"run.sql`" `"{0}`" `"{1}`"" -f $fname, $SqlLogPath
    }
    else
    {
      #                 /
      $cmdLine = "`"{0}{1}{2}`@{3}`"" -f $db_user, $(if ($pwd -ne $null) { "/" }), $pwd, $cfg_local[$db]
      $cmdLine = $cmdLine.PadRight(30)
      $cmdLine += " `@`"run.sql`" `"{0}`" `"{1}`"" -f $fname, $SqlLogPath
    }
    write-verbose("sqlplus.exe -L " + $cmdLine);
    $cmds += $cmdLine
  }
  $cmds
}


FormatTaskName "[{0}]"

task unit-test -depends Init, Clean, TestConnect, ShowSettings, ShowSettingsDetails, Accept

task default -depends run

Task run -depends Init, Clean, TestConnect, ShowSettings, Accept, Invoke-sqlplus, Archive -description "Do it"


filter Skip-Empty { $_|?{ $_ -ne $null -and $_} }

<#
Need to define all variables here used through out the script (Except for locals for each task)
#>


properties {
  $script:config_vars=@()
  Set-Variable -Name "JobDir"          -Description "Literal Path of the directory containing the ControlM batch file and associated sql files." -value $(Resolve-Path .)
  Set-Variable -Name "initFile"        -Description "SDLC configuration file"
  write-verbose("initFile=$initFile")
  write-verbose("sdlc_environment=$sdlc_environment")
  write-verbose("JobName=$JobName")

#  Set-Variable -Name "base_dir" -Description "Same as JobDir except but by `$executionContext.SessionState.Path.CurrentLocation " -value $($executionContext.SessionState.Path.CurrentLocation)

  $x=[System.DateTime]::Now
  Set-Variable -Name "IsoDateTimeStr"  -Description "Time and Date Stamp string" -Value $([string]::Format('{0}-{1:d2}-{2:d2}T{3:d2}-{4:d2}-{5:d2}',$x.year,$x.month,$x.day,$x.hour,$x.minute,$x.second))
  Set-Variable -Name "TempDir"         -Description "Temporary output files of the job." -value $($env:TEMP)

  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
    'sdlc_environment'
    ,'initFile'
    ,'cfg_local'
    ,'cfg_sqlSpec'
    ,'IsoDateTimeStr'
    ,'JobDir'
    ,'JobName'
    ,'TempDir'
    ,'VerbosePreference'
    ,'PoshLogPathAbs'
    )
  Set-Variable -Name "sdlc_environment" -Description "System Development Life Cycle Environment" -value $sdlc_environment

  Set-Variable -Name "cfg_local"     -Description "Oracle Service" -value ""

  Set-Variable -Name "cfg_sqlSpec" -Description "Sql file wild cards spec" -value $($cfg_sqlSpec)

  $script:config_vars += @("PoshLogPathAbs" )
  Set-Variable -Name "PoshLogPathAbs" -Description "Powershell logging file used by Start-Transcript" -value $(join-path -Path $JobDir -ChildPath $($JobName + "." + $IsoDateTimeStr + ".log"  ))

  write-verbose("initFile {0}" -f $initfile);

  if (test-path ".\$initFile") {
    write-host("Config File:{0}" -f  ".\$initFile")
    Get-Content ".\$initFile" | Skip-Empty | Invoke-Expression
  }
  else
  {
     throw "$initFile not found"
  }

  $script:config_vars += @("SqlLogPathAbs" )
  set-variable -Name "SqlLogPathAbs" -Description "Sql log filename (rooted)"                        -value $(join-path -Path $JobDir -ChildPath $( $JobName  + "." + $sdlc_environment + "." + $IsoDateTimeStr + ".log"  ))

  $script:config_vars += @("ArchiveZipPath" )
  Set-Variable -Name "ArchiveZipPath"  -Description "ArchiveZipPath" -value  $(join-path -Path $JobDir  -ChildPath $( $JobName + "." + $sdlc_environment  + "." + $IsoDateTimeStr + ".zip"  ))

  $script:config_vars += @("ArchiveZipContentFileSpec" )
  Set-Variable -Name "ArchiveZipContentFileSpec" -Description "ArchiveZipContentFileSpec" -value  $(join-path -Path $JobDir  -ChildPath "*.log")

  if ($cfg_sqlSpec -eq $null) {
    $cfg_sqlSpec = @("[0-9_][0-9_][0-9_]_*-*.sql","[0-9_][0-9_][a-z]_*-*.sql")
  }
  $script:sqlfiles = Resolve-Path -Path @($cfg_sqlSpec) | sort-object -Unique
  $script:credFiles = @()
}


task Init -Description "Initialize the environment" {
  $script:sqlfiles | Out-String | write-verbose
  $script:cmdlines = parseSqlFilename @($sqlfiles)
}


task TestConnect -depends Init -description "Test username and password connections"{
  #Expected format of cmdlines
  #"russell/rusty@ONCD.world" @"run.sql" "___entr......
  $l_connections=@()
  foreach ($i in $script:cmdlines)
  {
    #parse up to the first space
    if ($i -match '^"([A-Za-z_/@\.]+)" .*')
    {
      Write-verbose  $("{0}" -f $matches[1])
      if ($l_connections -notcontains $matches[1])
      {
        $l_connections += $matches[1]
      }
    }
  }
  foreach ($z in $l_connections)
  {
    $cmd = "echo.exit|sqlplus.exe -L {0}" -f $z
    Write-Host "cmd.exe /c " $cmd
    & cmd.exe /c ""$cmd""
    if ($lastexitcode -ne 0)
    {
      throw ("Exec: " + "sqlplus.exe exited with a failure of $lastexitcode running: cmd.exe /c $cmd")
    }
  }
}


task clean -Description "Remove the previous generated files in the JobDir"  {
  Get-Childitem -LiteralPath $JobDir -Filter "*.log" | Where-Object {-Not $_.PSIsContainer} | Foreach-Object {Remove-Item $_.FullName}
}


task Invoke-Sqlplus -depends Init, Accept -Description "Executes sqlplus.exe, Spool file specified as second parameter on command line"  {

  try {
        @($script:cmdlines).GetEnumerator() | %{
          write-host("sqlplus.exe -L {0}" -f $_  )
          exec {sqlplus.exe -L $_ }
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


task ShowSettings -depends Init -Description "Display the configuration variables values" {
  Start-Transcript -Path $PoshLogPathAbs
  $ErrorActionPreference = "Continue"
  #$script:config_vars | get-variable | sort-object -unique -property "Name" | Select-Object Name,value,Description, options | Format-table @{n='Name';e={$_.Name};align='left';w=30},@{n='Value';e={$_.Value};align='left';w=50},Description -wrap | Out-String
  $script:config_vars | get-variable | sort-object -unique -property "Name" | Select-Object Name,value,Description, options | Format-list | Out-Host
  @($script:sqlfiles).GetEnumerator() | Sort-Object | format-table -auto | Out-Host
  Get-Variable -name @("sdlc*","cfg_*") | Format-Table -property name, value -autosize | Out-Host
  $cfg_local.GetEnumerator() | Sort-Object Name | format-table -auto | Out-Host
  Write-Host "Credential Files`r`n----------------"
  $script:credFiles | Out-String | Out-Host
  Write-Host "SQL Plus`r`n--------"
  $script:cmdlines | Out-String | Out-Host
}

task Accept -Description "Visual confirmation that we are hitting the correct configuration "{
  $confirmation = read-Host -Prompt "Press Return to Continue"
}

task ShowConfigFile -Description "Show the content of the configuration file." {

 if (test-path ".\$initFile") {
    write-host("Config File:{0}" -f  ".\$initFile")
    Get-Content ".\$initFile" | Write-host
  }
  else
  {
     throw "$initFile not found"
  }
}
