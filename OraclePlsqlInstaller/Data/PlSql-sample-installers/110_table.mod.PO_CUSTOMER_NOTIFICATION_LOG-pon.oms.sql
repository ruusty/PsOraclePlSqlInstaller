/*

Alter the po_customer_notification_log table

Add

*/

define l_owner=OMS
variable own varchar2(40)
execute select '&l_owner.' into :own from dual;

show user


alter session set current_schema = &l_owner;
whenever sqlerror exit failure rollback
--whenever sqlerror continue


define tabname=PO_CUSTOMER_NOTIFICATION_LOG
define tabname


--============================================================={
define colname=MAIL_INDICATOR
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. modify (
 &colname.      VARCHAR2(32 BYTE)
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


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS 'Delivery Method from  oms.PO_NOTIFICAT_DELIVER_VL.value';



--=============================================================}



--============================================================={
define colname=PROJECT_ID
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. ADD (
 &colname.      number(10)
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


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS 'The  OMS.PO_NOTIFICATION_HEADER.id of the Originating Planned Outage Notification ';


--=============================================================}


--============================================================={
define colname=RETAILER_NO_LEGAL_ENTITY
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. ADD (
 &colname.      number(9)
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


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS 'The  Retailer Legal Entity See PO_RETAILER.no_legal_entity ';


--=============================================================}


COMMENT ON TABLE   &l_owner..&tabname.                      IS 'Planned Outage Notification list of customers to be send Outage Notification letters. [Not all columns have ref integrity]';

COMMENT ON COLUMN  &l_owner..&tabname..ID                   is 'Source:oms.po_notification_customs.po_notification_cust';
COMMENT ON COLUMN  &l_owner..&tabname..notification_task_id is 'Notification Task ID from Source:OMS.PO_NOTIFICATION_TASK.id';
COMMENT ON COLUMN  &l_owner..&tabname..start_time           is 'Task Start DateTime';
COMMENT ON COLUMN  &l_owner..&tabname..end_time             is 'Task End DateTime';
COMMENT ON COLUMN  &l_owner..&tabname..cis_no_account       is 'Source:oms.ched_customer.cis_account_number';
COMMENT ON COLUMN  &l_owner..&tabname..requested_by         is 'The Applicant';
COMMENT ON COLUMN  &l_owner..&tabname..notification_type    is 'Defines the letter content, Source:OMS.PO_NOTIFICATION_TYPE.CODE';
COMMENT ON COLUMN  &l_owner..&tabname..date_sent            is 'Date Notices Published';
COMMENT ON COLUMN  &l_owner..&tabname..date_requested       is 'Date the Notices are to be published';
COMMENT ON COLUMN  &l_owner..&tabname..nmi                  is 'National Metering Identifier Source:oms.po_notification_cust.nmi';

