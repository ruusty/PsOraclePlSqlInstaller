--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

alter session set current_schema = &l_owner.;

SELECT * FROM global_name;



alter session set current_schema = &l_owner;
whenever sqlerror exit failure rollback

define pkg_name=CHED_UTILS


@@ OMS\sql_packages\OMS.CHED_UTILS.pks



@@ OMS\sql_packages\OMS.CHED_UTILS.pkb


@@ OMS\sql_packages\OMS.CHED_UTILS_perms.sql




DECLARE
  compile_invalid boolean := FALSE;
BEGIN
   DBMS_UTILITY.COMPILE_SCHEMA( :own, compile_invalid );
END;
/


undefine pkg_name


