--Build the Unplanned Message Publisher Monitor Procedure (used by the Scheduler Job) to monitor the Publishing job
--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

alter session set current_schema = &l_owner.;


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
