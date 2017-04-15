/*
Create a trigger to log changes on PO_NOTIFICATION_HEADER.Start_status
*/

define l_owner=OMS
variable own varchar2(40)
execute select '&l_owner.' into :own from dual;

show user


alter session set current_schema = &l_owner;
whenever sqlerror exit failure rollback


define tabname=PO_NOTIFICATION_HEADER
define tabname

--shortened version
define abbrv=PO_NOTIFICAT_HEADER
define abbrv

--============================================================={


CREATE OR REPLACE TRIGGER &l_owner..BI_&abbrv.
BEFORE UPDATE
OF START_STATUS
ON PO_NOTIFICATION_HEADER
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
WHEN (lower(NEW.start_status) = 'cancelled' and new.parent_project_id is null)
/*
When a project is cancelled from PON by "Edit Start Status"            start_status is  updated with 'cancelled'
When a project is cancelled from PON by  "Order Cancellation Letters"  start status is updated with 'cancelled-letter'  (not selectable from PON) and not trapped here
When the new matching PON project of type "CAN" is created by "Order Cancellation Letters"  it is an insert statement so not trapped here
*/
BEGIN

   INSERT INTO PO_NOTIFICAT_STATUS_LOG (
        ID
      , PROJECT_ID
      , START_STATUS_AFTER
      , START_STATUS_BEFORE
      , SYS_DATE_CREATE
      )
   VALUES (
       PO_NOTIFICAT_STATUS_LOG_SEQ.nextval
      ,:OLD.id
      ,:NEW.start_status
      ,:OLD.START_status
      , systimestamp
      );
      

EXCEPTION
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
     null;
END;
/



--=============================================================}


--check for invalid triggers
declare
num_invalid_objs PLS_INTEGER := 0;
CURSOR user_triggers_cur IS
with t as
  (select /*+ materialize */ user owner, t.trigger_name, t.status, t.table_name, t.table_owner, trim(t.base_object_type) base_object_type
   from user_triggers t
   where 1=1),
  o as
  (select /*+ materialize */ user owner, o.object_name, o.status valid, o.object_id, o.last_ddl_time, o.created
   from user_objects o
   where o.object_type = 'TRIGGER')
Select T.owner, T.trigger_name, T.status, T.table_name, T.table_owner, T.base_object_type, O.Valid, O.object_id, O.last_ddl_time, O.created
from t, o
where t.owner = o.owner
and t.trigger_name = o.object_name
and t.table_owner =  :own
AND valid = 'INVALID';

BEGIN

FOR r IN user_triggers_cur LOOP
   dbms_output.put_line (r.trigger_name);
   execute IMMEDIATE 'alter trigger ' || r.trigger_name || ' compile';
END LOOP;

FOR r IN user_triggers_cur LOOP
   num_invalid_objs := num_invalid_objs + 1;
   dbms_output.put_line ('ERR>Invalid TRIGGER ' || R.trigger_name);
END LOOP;


if num_invalid_objs >0  then
   RAISE_application_error(-20010, 'FATAL> ' || num_invalid_objs || ' invalid triggers  found in ' || :own);
  NULL;
end if;
END;
/


