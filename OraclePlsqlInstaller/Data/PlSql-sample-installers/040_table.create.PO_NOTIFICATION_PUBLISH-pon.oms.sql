/*

Create the table
PO_NOTIFICATION_PUBLISH_LAST table for Planned Outage

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


define tabname=PO_NOTIFICATION_PUBLISH_LAST
define tabname

--shortened version
define abbrv=PO_NOTIF_PUB_L
define abbrv

--============================================================={

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(2000);
BEGIN
  SQLSTR :=
'  CREATE TABLE "&l_owner."."&tabname."
   (
     ID                          NUMBER(10,0),
     PROJECT_ID                  NUMBER(10,0),
     NOTIFICATION_TASK_ID        NUMBER(10,0),
     NOTIFICATION_TYPE           VARCHAR2(10),
     NOTIFICATION_DESC           VARCHAR2(40),
     OUTAGE_WINDOW_START         DATE,
     OUTAGE_WINDOW_END           DATE,
     NMI                         VARCHAR2(30),
     CD_COMPANY_SYSTEM           VARCHAR2(4),
     ACCOUNT_NO                  VARCHAR2(30), /* tbd varchar or number9*/
     GIS_ID                      varchar2(30), /* tbd varchar or number9*/
     CIS_NO_ACCOUNT              NUMBER(9,0),
     NO_PROPERTY                 NUMBER(9,0),
     DELIVERY_METHOD             VARCHAR2(32),
     DATE_SENT                   DATE,
     DATE_REQUESTED              DATE,
     RETAILER_NO_LEGAL_ENTITY    NUMBER(9,0),
     RETAILER_NAME               varchar2(80),
     SERVICE_ADDRESS             varchar2(80),
     CUSTOMER_LEGAL_ENTITY_ID    NUMBER(9,0),
     CUSTOMER_NAME               varchar2(85),
     CUSTOMER_POSTAL_ADDRESS     varchar2(200),
     IS_LIFE_SUPPORT             varchar2(10)
   ) SEGMENT CREATION IMMEDIATE
  PCTFREE 10 PCTUSED 0 INITRANS 1 MAXTRANS 255
 NOCOMPRESS LOGGING
  TABLESPACE "OMS_DATA"
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



COMMENT ON TABLE    &l_owner..&tabname.                       IS 'Planned Outage Notification list of customer details sent to fulfilment house. Contains the last iteration of oms.planned_outage.publish_fullfilment_notices';

COMMENT ON COLUMN "&l_owner."."&tabname."."ID"                          IS 'Source:oms.PO_CUSTOMER_NOTIFICATION_LOG.id';
COMMENT ON COLUMN "&l_owner."."&tabname."."PROJECT_ID"                  IS 'The  OMS.PO_NOTIFICATION_HEADER.id of the Originating Planned Outage Notification ';
COMMENT ON COLUMN "&l_owner."."&tabname."."NOTIFICATION_TASK_ID"        IS 'Notification Task ID from Source:OMS.PO_CUSTOMER_NOTIFICATION_LOG.id';
COMMENT ON COLUMN "&l_owner."."&tabname."."NOTIFICATION_TYPE"           IS 'letter type Abbrev';
COMMENT ON COLUMN "&l_owner."."&tabname."."NOTIFICATION_DESC"           IS 'letter type descripton';
COMMENT ON COLUMN "&l_owner."."&tabname."."OUTAGE_WINDOW_START"         IS 'Task Start DateTime';
COMMENT ON COLUMN "&l_owner."."&tabname."."OUTAGE_WINDOW_END"           IS 'Task End DateTime';
COMMENT ON COLUMN "&l_owner."."&tabname."."NMI"                         IS 'National Metering Identifier Source:oms.po_notification_cust.nmi';
COMMENT ON COLUMN "&l_owner."."&tabname."."CD_COMPANY_SYSTEM"           IS '';
COMMENT ON COLUMN "&l_owner."."&tabname."."ACCOUNT_NO"                  IS 'Contains the GIS id';
                    
COMMENT ON COLUMN "&l_owner."."&tabname."."GIS_ID"                      IS 'Contains the GIS id varchar2';
COMMENT ON COLUMN "&l_owner."."&tabname."."CIS_NO_ACCOUNT"              IS 'Source:oms.ched_customer.cis_account_number';
                    
COMMENT ON COLUMN "&l_owner."."&tabname."."NO_PROPERTY"                 IS 'CIS Property Number';
COMMENT ON COLUMN "&l_owner."."&tabname."."DELIVERY_METHOD"             IS 'PON Delivery Method';
COMMENT ON COLUMN "&l_owner."."&tabname."."DATE_REQUESTED"              IS 'Print/publish date';
COMMENT ON COLUMN "&l_owner."."&tabname."."RETAILER_NO_LEGAL_ENTITY"    IS 'CIS Retailer Number';
COMMENT ON COLUMN "&l_owner."."&tabname."."RETAILER_NAME"               IS 'OMS Retailer Name';
COMMENT ON COLUMN "&l_owner."."&tabname."."SERVICE_ADDRESS"             IS 'CIS Service Address';
COMMENT ON COLUMN "&l_owner."."&tabname."."CUSTOMER_LEGAL_ENTITY_ID"    IS 'CIS Customer Legal entity id';
COMMENT ON COLUMN "&l_owner."."&tabname."."CUSTOMER_NAME"               IS 'CIS Customer Name';
COMMENT ON COLUMN "&l_owner."."&tabname."."CUSTOMER_POSTAL_ADDRESS"     IS 'CIS Customer Postal Address';
COMMENT ON COLUMN "&l_owner."."&tabname."."IS_LIFE_SUPPORT"             IS 'CIS Life support TRUE/FALSE/UNKNOWN';




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

define idxname=&abbrv._NMI_IDX
define idxname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(500);
BEGIN
  SQLSTR :=
'
CREATE  INDEX &l_owner..&idxname. ON &l_owner..&tabname.
(NMI)
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

GRANT SELECT ON OMS.&tabname. TO OMS_RE;

GRANT SELECT ON OMS.&tabname. TO OMS_RO;

GRANT DELETE, INSERT, SELECT, UPDATE ON OMS.&tabname. TO OMS_SUPPORT;

--=============================================================}


