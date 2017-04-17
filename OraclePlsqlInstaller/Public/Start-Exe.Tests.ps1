$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
<#
Invoke-Pester                         -Script @{ Path = '.\Start-Exe.Tests.ps1' }
Invoke-Pester -testname "Start-Exe"   -Script @{ Path = '.\Start-Exe.Tests.ps1' }
pester.bat -Script @{ Path = '.\Start-Exe.Tests.ps1' }
#>
Write-Host  "$here\$sut"
. "$here\$sut"
  $TnsName = "POND.WORLD"

Describe "Start-Exe" {
  $DestDir = Join-Path $([System.IO.Path]::GetTempPath())  $([System.IO.Path]::GetRandomFileName())
  $NonExistantDestDir = Join-Path $([System.IO.Path]::GetTempPath())  $([System.IO.Path]::GetRandomFileName())
  $ReportDate = [System.DateTime]::Now.ToString("yyyy-MM-ddTHH-mm-ss");
  
  $dependencies = @(
    @{
      Label = "Folder $DestDir exists"
      Test = { Test-Path -Path $DestDir -Type Container }
      Action = {
        mkdir -Path $DestDir -verbose
        start $DestDir
        start-sleep -Seconds 1
      }
    }
    
    @{
      Label = "Create pl/sql to execute"
      Test = {
        Test-Path -Path $(Join-Path $DestDir "run01.sql") -Type Leaf
        Test-Path -Path $(Join-Path $DestDir "run02.sql") -Type Leaf
        Test-Path -Path $(Join-Path $DestDir "run03.sql") -Type Leaf
        }
      Action = {
        #create a pl/sql file that creates a log file and is successful
        ##sqlplus -L /@pond.world @run01.sql "logfile.log"
@'
set termout on
set echo on
set linesize 1024
SET trimspool ON
set pagesize 1000
COLUMN  global_name format a40
alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';

variable call_status number
whenever sqlerror exit failure rollback

spool &1
SELECT global_name FROM global_name;
show USER
select 'Hello World' as "test_case"  from dual;
exit 0
/
spool off
'@ | set-content $(Join-Path $DestDir "run01.sql")
        
        #Create a sql file that make sqlplus return SUCCESS
        #sqlplus -L /@pond.world @run02.sql "logfile.log"
@'
set termout on
set echo on
set linesize 1024
SET trimspool ON
set pagesize 1000
COLUMN  global_name format a40
alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';

variable call_status number
whenever sqlerror exit failure rollback

spool &1
SELECT global_name FROM global_name;
show USER
begin
select 201 into :call_status from dual;

IF :call_status > 0  THEN
   RAISE_application_error(-20201, 'WARNING>Passing error condition' );
END IF;
exception when no_data_found then
    select 0 into :call_status from dual;
    null;
end;
/

print call_status
exit :call_status

'@ | set-content $(Join-Path $DestDir "run02.sql")
        
        #Create a sql file that make sqlplus return 64
        #sqlplus -L /@pond.world @run03.sql "logfile.log"
@'
set termout on
set echo on
set linesize 1024
SET trimspool ON
set pagesize 1000
COLUMN  global_name format a40
alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';

variable call_status number
whenever sqlerror exit failure rollback

spool &1
SELECT global_name FROM global_name;
show USER
select 'Hello World' as "test_case"  from dual;
exit 64
'@ | set-content $(Join-Path $DestDir "run03.sql")
      }
    }
  )
  
  foreach ($dep in $dependencies)
  {
    Write-Host $("Checking {0}" -f $dep.Label)
    & $dep.Action
    if (-not (& $dep.Test))
    {
      throw "The check: $($dep.Label) failed. Halting all tests."
    }
  }
  
  
  Context -Name "Execution" {
    
    $spArgs = @{
      FilePath = "echo-args.exe"
      ArgumentList = "arg1 arg2 arg2";
      WorkingDirectory = $DestDir;
      LogPath = Join-Path $DestDir "echo-args.$ReportDate.log"
    }
    
    It "Should throw bad exe" {
      { Start-Exe @spArgs } | Should throw
    }
    
    
    It "Should throw non-existant exe" {
      $spArgs.FilePath = "not-found.exe"
      { Start-Exe @spArgs } | Should throw
    }
    
    It "Should create ping log file" {
      $spArgs.FilePath = "ping.exe"
      $spArgs.LogPath = Join-Path $DestDir "ping;1.$ReportDate.log"
      { Start-Exe @spArgs } | Should throw
      Test-Path $spArgs.LogPath | Should be $true
    }
    It "Should create ping localhost log file" {
      $spArgs.FilePath = "ping.exe"
      $spArgs.ArgumentList = "localhost";
      $spArgs.LogPath = Join-Path $DestDir "ping;2.$ReportDate.log"
      { Start-Exe @spArgs } | Should not throw
      Test-Path $spArgs.LogPath | Should be $true
    }
    
    It "PL/SQL Should file create log file" {
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run01.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run01.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $DestDir "run01.sql.start-exe.log"); WorkingDirectory = $DestDir;}
      { Start-Exe @spArgs } | Should not throw
      Test-Path $spArgs.LogPath | Should be $true      
    }
    
    It "Should Create a log file and Throw exception" {
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run02.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run02.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $DestDir "run02.sql.start-exe.log"); WorkingDirectory = $DestDir;}
      { Start-Exe @spArgs } | Should throw
      Test-Path $spArgs.LogPath | Should be $true
      
    }
    
    It "Should create a log file and Throw System.Management.Automation.RuntimeException" {
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run03.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run03.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $DestDir "run03.sql.start-exe.log"); }
      { Start-Exe @spArgs } | Should throw
      try
        {
        Start-Exe @spArgs
        Throw [System.Exception] "Shouldn;t get here"
        }
        catch
        {
        $_.Exception.GetType().FullName | Should BeLikeExactly 'System.Management.Automation.RuntimeException'
        $_.Exception.Message | Should Not BeNullOrEmpty
        $LastExitCode | Should BeExactly 64
        }
      Test-Path $spArgs.LogPath | Should be $true
      }
    
    It "Should return LastErrorCode == 64" {
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run03.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run03;2.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $DestDir "run03.sql.start-exe-64.log"); WorkingDirectory = $DestDir; }
      try
      {
        Start-Exe @spArgs
        Throw [System.Exception] "Shouldn;t get here"
      }
      catch
      {
        $LastExitCode | Should BeExactly 64
      }
      Test-Path $spArgs.LogPath | Should be $true
    }
    
    It "Should not fail when output folder of log file  doesn't exist"{
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run01.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run01;2.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $NonExistantDestDir "run01.sql.start-exe;2.log"); WorkingDirectory = $DestDir; }
      { Start-Exe @spArgs } | Should not throw
    }
    
    It "Should not fail when WorkingDirectory doesn't exist"{
      $cmdLine = @("-L")
      $cmdLine += @("/@{0}" -f $TnsName)
      $cmdLine += @('@"{0}"' -f $(Join-Path $DestDir "run01.sql"))
      $cmdLine += @('"{0}"' -f $(Join-Path $DestDir "run01;2.sql.log"))
      $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
      $spArgs = @{ "FilePath" = "sqlplus.exe"; "ArgumentList" = $cmdLine; "LogPath" = $(Join-Path $DestDir "run01.sql.start-exe;2.log"); WorkingDirectory = $NonExistantDestDir; }
      { Start-Exe @spArgs } | Should not throw
    }
  }
}
