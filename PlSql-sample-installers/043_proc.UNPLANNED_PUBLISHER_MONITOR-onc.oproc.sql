--Build the Unplanned Message Publisher Monitor Procedure (used by the Scheduler Job) to monitor the Publishing job
define l_owner=OPROC

variable own varchar2(40)
execute select '&l_owner.' into :own from dual;
show user

SELECT * FROM global_name;

alter session set current_schema = &l_owner;

whenever sqlerror exit failure rollback
--whenever sqlerror continue


define proc_name=UNPLANNED_PUBLISHER_MONITOR

@@ OPROC\sql_procedures\OPROC.UNPLANNED_PUBLISHER_MONITOR.SQL
show errors PROCEDURE &l_owner..&proc_name.


@@ OPROC\sql_procedures\OPROC.UNPLANNED_PUBLISHER_MONITOR_perms.sql



DECLARE
  compile_invalid boolean := FALSE;
BEGIN
   DBMS_UTILITY.COMPILE_SCHEMA( :own, compile_invalid );
END;
/


set echo off
--
-- Valid Packages remaining
--
COLUMN OBJECT_NAME format A32 wrapped

select object_name,object_type,created, last_ddl_time,status from user_objects where object_name  IN ( '&proc_name.') and status = 'VALID';


declare
num_valid_objs pls_integer;
begin
   num_valid_objs :=0;
select count(*) into num_valid_objs from (
select object_name,object_type,created, last_ddl_time,status from user_objects where object_name IN ( '&proc_name.') and status = 'VALID'
);

if num_valid_objs <> 1  then
  RAISE_application_error(-20010, 'FATAL> ' || num_valid_objs || ' invalid objects found');
  NULL;
end if;
end;
/

undefine proc_nam
