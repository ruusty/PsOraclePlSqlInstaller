/*

Comments

*/

define l_owner=OMS
variable own varchar2(40)
execute select '&l_owner.' into :own from dual;

show user


alter session set current_schema = &l_owner;
whenever sqlerror exit failure rollback

define pkg_name=CHED_ORDER_UTILS


@@ OMS\sql_packages\OMS.CHED_ORDER_UTILS.pks
show errors PACKAGE &pkg_name.


@@ OMS\sql_packages\OMS.CHED_ORDER_UTILS.pkb
show errors PACKAGE BODY &l_owner..&pkg_name.


@@ OMS\sql_packages\OMS.CHED_ORDER_UTILS_perms.sql




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

select object_name,object_type,created, last_ddl_time,status from user_objects where object_name  = '&pkg_name.' and status = 'VALID';


declare
num_valid_objs pls_integer;
begin
   num_valid_objs :=0;
select count(*) into num_valid_objs from (
select object_name,object_type,created, last_ddl_time,status from user_objects where object_name  = '&pkg_name.' and status = 'VALID'
);

if num_valid_objs <> 2  then
  RAISE_application_error(-20010, 'FATAL> ' || num_valid_objs || ' insufficient valid objects found in ' || :own);
  NULL;
end if;
end;
/




undefine pkg_name

