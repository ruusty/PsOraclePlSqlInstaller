/*

Comments

*/
--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

EXECUTE alter session set current_schema = :OWN;


define pkg_name=PKG_EFC


--@@ OMS_EFC\sql_packages\OMS_EFC.PKG_EFC.pks
--show errors PACKAGE &pkg_name.


@@ OMS_EFC\sql_packages\OMS_EFC.PKG_EFC.pkb
show errors PACKAGE BODY &l_owner..&pkg_name.



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


