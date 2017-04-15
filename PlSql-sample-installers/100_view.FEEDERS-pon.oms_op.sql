define l_owner=OMS_OP

variable own varchar2(40)
execute select '&l_owner.' into :own from dual;
show user

SELECT * FROM global_name;

alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';
alter session set current_schema = &l_owner;

whenever sqlerror exit failure rollback



define viewname=FEEDERS

@@ OMS_OP\sql_views\OMS_OP.FEEDERS.sql
show error VIEW &viewname.

@@ OMS_OP\sql_views\OMS_OP.FEEDERS_perms.sql


select * from all_objects where object_type = 'VIEW' and status = 'VALID' and owner = :own  AND object_name = '&viewname.';

declare
num_invalid_objs pls_integer;
begin
   num_invalid_objs :=0;
select count(*) into num_invalid_objs from all_objects where object_type = 'VIEW' and status = 'VALID' and owner = :own  AND object_name = '&viewname.';

if num_invalid_objs <> 1  then
   RAISE_application_error(-20010, 'FATAL> ' || num_invalid_objs || ' invalid objects found in ' || :own);
end if;
end;
/

undefine viewname


define viewname=UNPLANNED_NMI

@@ OMS_OP\sql_views\OMS_OP.UNPLANNED_NMI.sql
show error VIEW &viewname.

@@ OMS_OP\sql_views\OMS_OP.UNPLANNED_NMI_perms.sql



select * from all_objects where object_type = 'VIEW' and status = 'VALID' and owner = :own  AND object_name = '&viewname.';

declare
num_invalid_objs pls_integer;
begin
   num_invalid_objs :=0;
select count(*) into num_invalid_objs from all_objects where object_type = 'VIEW' and status = 'VALID' and owner = :own  AND object_name = '&viewname.';

if num_invalid_objs <> 1  then
   RAISE_application_error(-20010, 'FATAL> ' || num_invalid_objs || ' invalid objects found in ' || :own);
end if;
end;
/

undefine viewname



