/*

Create the function  oms.printf

*/
--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

alter session set current_schema = &l_owner.;


define func_name=PRINTF


@@ OMS\sql_functions\OMS.PRINTF.sql
show errors FUNCTION &func_name.

@@ OMS\sql_functions\OMS.PRINTF_perms.sql

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

select object_name,object_type,created, last_ddl_time,status from user_objects where object_name  = '&func_name.' and object_Type = 'FUNCTION'and status = 'VALID';

declare
num_valid_objs pls_integer;
begin
   num_valid_objs :=0;
select count(*) into num_valid_objs from (
select object_name,object_type,created, last_ddl_time,status from user_objects where object_name  = '&func_name.' and object_Type = 'FUNCTION'and status = 'VALID'
);

if num_valid_objs <> 1  then
  RAISE_application_error(-20010, 'FATAL> ' || num_valid_objs || ' insufficient valid objects found in ' || :own);
  NULL;
end if;
end;
/




undefine func_name

