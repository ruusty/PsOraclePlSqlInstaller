/*

Alter the PO_NOTIFICATION_TYPE table for Planned Outage


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

define tabname=PO_NOTIFICATION_TYPE
define tabname

--============================================================={
define colname=DISPLAY_ORDER
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. ADD (
 &colname.      number(2)
)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -01430 THEN
      SQLSTR := 'SELECT COUNT(*) from user_tab_columns where table_name = ''&tabname'' and column_name = ''&colname.'' ' ;
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS 'Display Order in application';


--=============================================================}
define colname=ORDER_REQUIRED
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. ADD (
 &colname.      number(1)
)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -01430 THEN
      SQLSTR := 'SELECT COUNT(*) from user_tab_columns where table_name = ''&tabname'' and column_name = ''&colname.'' ' ;
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 1 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS '1-letter type requires an Order, 0-Letter type option';


--=============================================================}



--============================================================={
--M_F_PONH_CUST_NOTIFTYPE
--Remove the cascade delete from PO_CUSTOMER_NOTIFICATION_LOG

define constname=M_F_PONH_CUST_NOTIFTYPE
define constname



DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
ALTER TABLE OMS.PO_CUSTOMER_NOTIFICATION_LOG drop  CONSTRAINT &constname.
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -02443 THEN
      SQLSTR := 'SELECT COUNT(*) from user_constraints where constraint_name = ''&constname.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 0 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/



DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
ALTER TABLE OMS.PO_CUSTOMER_NOTIFICATION_LOG ADD (
  CONSTRAINT &constname.
  FOREIGN KEY (NOTIFICATION_TYPE)
  REFERENCES OMS.PO_NOTIFICATION_TYPE (CODE)
  ENABLE NOVALIDATE)
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -00955 OR SQLCODE = -02261 OR SQLCODE = -02260 THEN
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

--=============================================================}
--============================================================={
--Leave the existing notification_types and change display_order to < 0
--and be filtered out in the PON Application

SET DEFINE OFF;
--SQL Statement which produced this data:
--
--  SELECT
--     ROWID, ID, CODE, DESCRIPTION,
--     DISPLAY_ORDER, ORDER_REQUIRED
--  FROM OMS.PO_NOTIFICATION_TYPE;
--
MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  1 as id,
  'IN1' as code,
  'IN1 - Standard interruption' as description,
  1 as display_order,
  1 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  2 as id,
  'IN2' as code,
  'IN2 - Short interruption (eg generator)' as description,
  2 as display_order,
  1 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  3 as id,
  'IN3' as code,
  'IN3 - Tree Trimming (SECV & Council)' as description,
  -3 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  4 as id,
  'IN4' as code,
  'IN4 - Standard Interruption (no order)' as description,
  4 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  5 as id,
  'IN5' as code,
  'IN5 - Generator (10 min interrupt)' as description,
  -5 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  7 as id,
  'IN7' as code,
  'IN7 - Line Extension' as description,
  -7 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  8 as id,
  'IN8' as code,
  'IN8 - Essential Maintenance (Short Term)' as description,
  -8 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  9 as id,
  'IN9' as code,
  'IN9 - Equipment Test (10 min interrupt)' as description,
  -9 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  10 as id,
  'ACL' as code,
  'ACL - Inspection' as description,
  -10 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  11 as id,
  'CAN' as code,
  'CAN - Cancellation of Notice' as description,
  11 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  12 as id,
  'TV1' as code,
  'TV1 = IN1+ - Standard Interruption' as description,
  -12 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  13 as id,
  'VC1' as code,
  'VC1 = IN4+ - Reliability Improvements' as description,
  -13 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;

MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  6 as id,
  'IN6' as code,
  'IN6 - Road Alterations (Vic Roads)' as description,
  -6 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;



MERGE INTO OMS.PO_NOTIFICATION_TYPE A USING
 (SELECT
  14 as id,
  'CST' as code,
  'CST - Custom letter' as description,
  14 as display_order,
  0 as order_required
  FROM DUAL) B
ON (A.ID = B.ID)
WHEN NOT MATCHED THEN
INSERT (
  ID, CODE, DESCRIPTION, DISPLAY_ORDER, ORDER_REQUIRED)
VALUES (
  B.ID, B.CODE, B.DESCRIPTION, B.DISPLAY_ORDER, B.ORDER_REQUIRED)
WHEN MATCHED THEN
UPDATE SET
  A.CODE = B.CODE,
  A.DESCRIPTION = B.DESCRIPTION,
  A.DISPLAY_ORDER = B.DISPLAY_ORDER,
  A.ORDER_REQUIRED = B.ORDER_REQUIRED;


--=============================================================}


SET DEFINE ON;


--============================================================={

define constname=M_PONTY_&colname.
define constname


DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
ALTER TABLE &l_owner..&tabname. ADD
  CONSTRAINT &constname.
  CHECK (&colname. in (0,1))
  ENABLE
  VALIDATE
';
  EXECUTE IMMEDIATE SQLSTR;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line(SQLCODE);
    IF SQLCODE = -02264 THEN
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

--=============================================================}

COMMENT ON column oms.PO_NOTIFICATION_TYPE.code           IS 'The key of the notification';
COMMENT ON column oms.PO_NOTIFICATION_TYPE.description    IS 'Description of the notification';
