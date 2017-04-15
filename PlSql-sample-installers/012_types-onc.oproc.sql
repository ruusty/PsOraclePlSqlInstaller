-- The types

@@ OPROC\sql_types\OPROC.SMS_PUSH_MONITOR_T.sql
show errors TYPE SMS_PUSH_MONITOR_T

@@ OPROC\sql_types\OPROC.SMS_PUSH_MONITOR_T_perms.sql



@@ OPROC\sql_types\OPROC.SMS_PUSH_MONITOR_SET.sql
show errors TYPE SMS_PUSH_MONITOR_SET

@@ OPROC\sql_types\OPROC.SMS_PUSH_MONITOR_SET_perms.sql




@@ OPROC\sql_types\OPROC.SMS_PUSH_MESSAGE_T.sql
show errors TYPE SMS_PUSH_MESSAGE_T

@@ OPROC\sql_types\OPROC.SMS_PUSH_MESSAGE_T_perms.sql




@@ OPROC\sql_types\OPROC.SMS_PUSH_MESSAGE_SET.sql
show errors TYPE SMS_PUSH_MESSAGE_SET

@@ OPROC\sql_types\OPROC.SMS_PUSH_MESSAGE_SET_perms.sql





@@ OPROC\sql_types\OPROC.SMS_PUSH_NMI_SET.sql
show errors TYPE SMS_PUSH_NMI_SET

@@ OPROC\sql_types\OPROC.SMS_PUSH_NMI_SET_perms.sql


define typename=UNPLANNED_PUBLISH_T

BEGIN
  dbms_utility.get_dependency(TYPE   => 'TYPE',
                              SCHEMA => 'OPROC',
                              NAME   => '&typename.');
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;
/

--@@ OPROC\sql_types\OPROC.UNPLANNED_PUBLISH_T.sql

-- UNPLANNED_PUBLISH_T is used in the queue table UNPLANNED_PUBLISH_TAB
-- so if it exists skip the error


DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :='
CREATE OR REPLACE TYPE &typename.
AS OBJECT
(
 MOD_TIMESTAMP      TIMESTAMP(9)
,MOD_GUID           RAW (16)
)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -02303  THEN
      SQLSTR := 'SELECT COUNT(*) from user_types where type_name = ''&typename.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/



show errors TYPE UNPLANNED_PUBLISH_T

BEGIN
  dbms_utility.get_dependency(TYPE   => 'TYPE',
                              SCHEMA => 'OPROC',
                              NAME   => '&typename.');
EXCEPTION
   WHEN OTHERS THEN
      NULL;
END;
/

@@ OPROC\sql_types\OPROC.UNPLANNED_PUBLISH_T_perms.sql
