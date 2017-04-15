<#
  .SYNOPSIS
    Create run.sql file
  
  .PARAMETER folder
    Folder where the run.sql is created.
  
  .EXAMPLE
    		PS C:\> New-OracleRunFixture
  
#>
function New-OracleRunFixture
{
  [CmdletBinding()]
  param
  (
    [Parameter(Position = 1)]
    [string]$folder = $PWD
  )

$runPlsql =
  @"
set termout off
/*===========================================================================

Pl/Sql script wrapper for running pl/sql files with common settings and log file

Parameter 1
   pl/sql file to execute with sqlplus.exe

Parameter 2
   log file path. Used by the spool command

Example

sqlplus.exe user/pwd@connect_identifier @run.sql file_to_run.sql file_to_run.sql.log

===========================================================================*/
SET serveroutput ON SIZE unlimited
set termout on

SET DESCRIBE DEPTH 2
SET DESCRIBE INDENT ON
SET DESCRIBE LINE OFF
SHOW DESCRIBE

set echo on
set linesize 1024
SET trimspool ON
SET pagesize 999


column GLOBAL_NAME format a20 wrapped
column host_name   format a20 wrapped
column "Name"      format a40 wrapped
column COLUMN_NAME format a40 wrapped

alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';


spool "&2."

define

show user

SELECT GLOBAL_NAME FROM global_name;

whenever sqlerror exit failure rollback
--whenever sqlerror continue

@ "&1."

prompt SUCCESS
DISCONNECT
exit
"@
  
  $runPlsql | Set-Content -Path $(Join-Path $folder "run.sql")  -Encoding Ascii
}
