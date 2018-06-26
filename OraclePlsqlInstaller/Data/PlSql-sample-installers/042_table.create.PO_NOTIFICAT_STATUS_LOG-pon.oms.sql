
/*

Create the table
PO_NOTIFIC_STATUS_LOG table for Planned Outage

This table contains the changes to the PO_NOTIFICATION_HEADER.start_status


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

define tabname=PO_NOTIFICAT_STATUS_LOG
define tabname

--shortened version
define abbrv=PO_NOTIFICAT_STATUS_LOG
define abbrv

--============================================================={

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'create table &l_owner..&tabname.   (
     id                  number(10)
    ,project_id          number(10)
    ,sys_date_create     date  not null
    ,START_STATUS_before varchar2(20)
    ,START_STATUS_after  varchar2(20)
)
TABLESPACE OMS_DATA
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -00955 THEN
      SQLSTR := 'SELECT COUNT(*) from user_tables where table_name = ''&tabname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/



COMMENT ON TABLE    &l_owner..&tabname.                       IS 'Records changes of Planned Notification Projects when they are cancelled by selecting "Edit Start Status" from the PON application.';
COMMENT ON COLUMN   &l_owner..&tabname..SYS_DATE_CREATE       IS 'Date and time of message xml creation';
COMMENT ON COLUMN   &l_owner..&tabname..id                    is 'unique id  of change from a serial sequences';

COMMENT ON COLUMN   &l_owner..&tabname..project_id            is 'Planned Outage Project identifier';
COMMENT ON COLUMN   &l_owner..&tabname..START_STATUS_before   is 'Start Status before the change';
COMMENT ON COLUMN   &l_owner..&tabname..START_STATUS_after    is 'Start Status after the change';


--=============================================================}
--============================================================={

define idxname=&abbrv._PK
define idxname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
CREATE UNIQUE INDEX &l_owner..&idxname. ON &l_owner..&tabname.
(id)
LOGGING
TABLESPACE OMS_INDEX
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -00955 THEN
      SQLSTR := 'SELECT COUNT(*) from user_indexes where index_name = ''&idxname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


--=============================================================}
--============================================================={


define constname=PK_&abbrv.
define constname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
ALTER TABLE &l_owner..&tabname. ADD (
   CONSTRAINT  &constname.
   PRIMARY KEY (id)
   USING INDEX &l_owner..&idxname.
   ENABLE VALIDATE)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -2260  THEN
      SQLSTR := 'SELECT COUNT(*) from user_constraints where constraint_name = ''&constname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


--=============================================================}
--============================================================={

define seqname=&abbrv._SEQ
define seqname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'CREATE SEQUENCE OMS.&seqname.
START WITH 1
INCREMENT BY 1
MINVALUE 0
NOCACHE
NOCYCLE
ORDER
';

  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -955  THEN
      SQLSTR := 'SELECT COUNT(*) from user_sequences where sequence_name = ''&seqname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


--=============================================================}
--============================================================={


CREATE OR REPLACE TRIGGER &l_owner..BI_&abbrv.
BEFORE INSERT
ON &l_owner..&tabname.
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
BEGIN
  :NEW.sys_date_create := systimestamp;
  IF :NEW.id IS NULL THEN
     :NEW.id :=&seqname..NEXTVAL;
  END IF;
END;
/

undefine seqname


--=============================================================}
--============================================================={

define constname=M_PNSL_FKEY1
define constname


DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
ALTER TABLE &l_owner..&tabname. ADD (
  CONSTRAINT &constname.
  FOREIGN KEY (project_id)
  REFERENCES &l_owner..PO_NOTIFICATION_HEADER(id)
  ON DELETE CASCADE
  ENABLE VALIDATE
)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -00955 OR SQLCODE = -02261 OR SQLCODE = -02260 OR SQLCODE = -02275 THEN
      SQLSTR := 'SELECT COUNT(*) from user_constraints where constraint_name = ''&constname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


undefine constname





GRANT SELECT ON OMS.&tabname. TO OMS_RE;

GRANT SELECT ON OMS.&tabname. TO OMS_RO;

GRANT DELETE, INSERT, SELECT, UPDATE ON OMS.&tabname. TO OMS_RW;

GRANT DELETE, INSERT, SELECT, UPDATE ON OMS.&tabname. TO OMS_SUPPORT;

grant select on oms.PO_NOTIFICAT_STATUS_LOG to oms_op with grant option;


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


