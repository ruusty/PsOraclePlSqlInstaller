
  CREATE OR REPLACE PACKAGE BODY "OMS"."PLANNED_OUTAGE" AS
--===========================================================================================================================
/*

    Project : GIS/OMS

Applic Name : Planned Outages

     Author : russell

       Date : 2016-07-11

Copyright (c) Ched Services

  Function :  Planned Network Outages application suite

Discussion :

RGH CR33194 2017-02-21 CR33194-PON for connected cust with valid SP
- publish_fullfilment_notices now NMI based.
- view PO_NOTIFICATION_PUBLISH replaced by PO_NOTIFICATION_PUBLISH_LAST

RGH CR32967 2016-07-11 CR32967-PlannedOutage-Lifesupport changes
- Publishes are executed the day after the publish Request Date.  Normally 00:15 the following day.
- The XML_DOC now has two date xml attributes.
   - The date_publish (rounded to the day) i.e. The requested_date to send the xml to the fulfilment house.
   - datetimestamp the time the xml report was generated

RGH CR30802 2015-05-29 Refactored to support new version of Planned Outage Notification VB application.
   xml document used for Fulfilment contractor and Retailers
   Scott Logan function to calculate the PON Status has been replaced with function oms.PO_NOTIFICATION_STATUS (now testable and avoids rescanning po_notification_header)

===========================================================================*/

gr_VERSION CONSTANT VARCHAR2(200) := '4.3.0.0';
gc_scope_prefix constant VARCHAR2(31) := lower($$PLSQL_UNIT) || '.';

--Hardcoded Notification Types for special handling
gc_NotifTypeCancellationNotice CONSTANT PO_NOTIFICATION_TYPE.CODE%TYPE := 'CAN';
gc_NotifTypeCustom             CONSTANT PO_NOTIFICATION_TYPE.CODE%TYPE := 'CST' ;
c_pubNmis_tab_name             CONSTANT VARCHAR2(32) NOT NULL := 'PO_NOTIFICATION_PUBLISH_LAST';

gc_xml_version                 constant  VARCHAR2(10) := '4.3.3';
--==============================================================================
--
-- Package vars
--
--Now configurable from oms.ched_config
c_days_in_past_expired  number(3) := 120;
c_past_days_recent      number(3) := 14;

cursor m_settings_cur is
select * from (
select name,value from ched_config
)
pivot (max(value) for name in (
    'PON!DEBUG_PKG'              as DEBUG_PKG
   ,'SDLC_ENVIRONMENT'           as SDLC_ENVIRONMENT
   ,'PON!DAYS_IN_PAST_EXPIRED'   as DAYS_IN_PAST_EXPIRED
   ,'PON!PAST_DAYS_RECENT'       as PAST_DAYS_RECENT
));

m_settings m_settings_cur%rowtype;

cursor destination_details_cur(p_project_id number) is
select
     h.id                  as project_id
   , h.order_id            as order_id
   , D.ID                  as po_destination_id
   from
   oms.po_notification_header h
   join poweron.po_int_elec_break poieb on H.INTERRUPTED_GIS_RWO_ID3 = POIEB.RWO_ID3 and POIEB.BUILD_VERSION  ='master'
   join poweron.po_destination d on D.GIS_RWO_ID3 = POIEB.RWO_ID3
   where
   h.id = p_project_id;

--
--Private Procedure Prototypes
--

--
--Public Procedure
--


--=============================================================================

FUNCTION getVersion return varchar2
IS
begin
    return gr_VERSION;
end getVersion;

Procedure status
is
begin
 dbms_output.put_line('FileVersion           :' || gr_VERSION);
 dbms_output.put_line('debug_pkg             :' || m_settings.debug_pkg);
 dbms_output.put_line('c_days_in_past_expired:' || c_days_in_past_expired);
 dbms_output.put_line('c_past_days_recent    :' || c_past_days_recent);
end status;


--=============================================================================
-- If the Outage date is c_days_in_past_expired delete
procedure REMOVE_OLD_NOTICES is
   cursor        v_cursor(days_in_past number) is
   select
        nh.project_id              as ponh_id
      , NH.PRINT_DATE
      , nh.applicant_name
      , nh.outage_date
      from OMS.PO_NOTIFICATION_PROJ_SUMMARY nh
      where outage_date < sysdate - days_in_past
   order by project_id;

   type ponhTab is table of v_cursor%rowtype;
   po_todelete ponhTab;

   v_no_projects number := 0;
   v_app         number;
   v_msg         varchar2(4000);

begin
   v_app := oms.ched_log_utils.start_application('REMOVE_OLD_NOTICES', 'Start');
   dbms_output.put_line('v_app=' ||v_app);

   open v_cursor(c_days_in_past_expired);
   fetch v_cursor bulk collect into po_todelete;
   CLOSE v_cursor;
   -- Walk the collection
   for l_row in po_todelete.first .. po_todelete.last
   loop
      v_no_projects := v_no_projects + 1;

      v_msg :=
                           'id:'          || po_todelete(l_row).ponh_id ||
       chr(10) || 'outage date :'         || po_todelete(l_row).outage_date ||
       chr(10) || 'date printed:'         || po_todelete(l_row).print_date ||
       chr(10) || 'applicant name:'       || nvl(po_todelete(l_row).applicant_name, '-') ;

      dbms_output.put_line('delete ' || po_todelete(l_row).ponh_id);
      dbms_output.put_line(v_msg);
      oms.ched_log_utils.write_to_log_autonomous('information', v_msg, v_app, '', '', 0, '', '', '', '');
      -- Cascade delete will clean up all the children
      delete oms.po_notification_header where id = po_todelete(l_row).ponh_id;
   end loop;


   oms.ched_log_utils.end_application(v_app, 'success', 'End (days = ' || c_days_in_past_expired || '). Deleted ' || v_no_projects || ' projects.');
   dbms_output.put_line('success'|| 'End (days = ' || c_days_in_past_expired || '). Deleted ' || v_no_projects || ' projects.');
EXCEPTION
   WHEN OTHERS THEN
      dbms_output.put_line(dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE);
      oms.ched_log_utils.end_application(v_app, 'failure', dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE );
   ROLLBACK;
END REMOVE_OLD_NOTICES;



--=============================================================================
PROCEDURE PO_CLONE_TASK_DEV_CUST
  (
    v_new_project_id         IN  NUMBER   --is the new project which already exists
   ,v_source_project_id      IN NUMBER    --is the project to clone the tasks, devices, customers
   )
/*
Discussion :
Clones the tasks , devices , and customers for a Planned Outage.
v_new_project_id    is the new project which already exists
v_source_project_id is the project to clone from

let the calling application commit / rollback

===========================================================================*/
IS

CURSOR c_tasks
IS
select pont.id, PONT.START_TIME, pont.end_time, pont.description, pont.feeder, pont.feeder_id
from
  oms.po_notification_header ponh
, oms.po_notification_task pont
where ponh.id = PONT.NOTIFICATION_HEADER_ID
and ponh.id = v_source_project_id;

CURSOR c_Devices( p_sourceTaskId in NUMBER )
IS
select
  POND.CUSTOMER_COUNT
, POND.DESCRIPTION
, POND.DEVICE_TYPE
, POND.ENERGISE_STATE
, POND.FACILITY_TYPE
, POND.GIS_RWO_ID3
, POND.HEIRARCHY
, POND.HV_RWOID
, POND.ID
, POND.LAST_OPERATION
, POND.NOTIFICATION_TASK_ID
, POND.OVERRIDE
, POND.RWO_TYPE
, POND.RWOID
, POND.STATE
from
 oms.po_notification_task   pont
,oms.po_notification_device pond
where POND.NOTIFICATION_TASK_ID = pont.id
and PONT.ID = p_sourceTaskId;

CURSOR c_CustomersOff ( p_sourceTaskId in NUMBER )
IS
SELECT
PONC.ID
 , PONC.NOTIFICATION_TASK_ID
 , PONC.FEEDERNAME
 , PONC.CUSTOMERTYPE
 , PONC.NMI
 , PONC.NAME
 , PONC.SERVICEADDRESS
 , PONC.POSTALADDRESS
 , PONC.PHONE
 , PONC.TRANSFORMER
 , PONC.GISID
 , PONC.MOVEINDATE
 , PONC.METERNUM
 , PONC.GIS_RWO_ID3
FROM
 oms.po_notification_task   pont
 ,OMS.PO_NOTIFICATION_CUST PONC
 where PONC.NOTIFICATION_TASK_ID = PONT.ID
 and PONT.ID = p_sourceTaskId;



BEGIN

-- Clone the tasks


FOR task IN c_tasks
LOOP
   insert into oms.po_notification_task(ID, NOTIFICATION_HEADER_ID, START_TIME, END_TIME,          DESCRIPTION,      FEEDER,      FEEDER_ID,      NOTIFICATION_TYPE)
   values (oms.po_notification_task_seq.nextval, v_new_project_id, task.start_time, task.end_time, task.description, task.feeder, task.feeder_id, gc_NotifTypeCancellationNotice);

   for d in c_Devices(task.id)
   loop
      INSERT INTO OMS.PO_NOTIFICATION_DEVICE (ID, NOTIFICATION_TASK_ID, GIS_RWO_ID3, RWO_TYPE, DESCRIPTION, CUSTOMER_COUNT, DEVICE_TYPE, FACILITY_TYPE, STATE, ENERGISE_STATE, LAST_OPERATION, OVERRIDE, RWOID, HV_RWOID, HEIRARCHY)
      VALUES (OMS.PO_NOTIFICATION_DEVICE_seq.nextval,oms.po_notification_task_seq.currval,d.GIS_RWO_ID3,d.RWO_TYPE,d.DESCRIPTION,d.CUSTOMER_COUNT,d.DEVICE_TYPE,d.FACILITY_TYPE,d.STATE,d.ENERGISE_STATE,d.LAST_OPERATION,d.OVERRIDE, d.RWOID, d.HV_RWOID, d.HEIRARCHY);
   end loop;

   for c in c_CustomersOff (task.id)
   loop
      INSERT INTO OMS.PO_NOTIFICATION_CUST (ID,NOTIFICATION_TASK_ID,FEEDERNAME,CUSTOMERTYPE,NMI,NAME,SERVICEADDRESS,POSTALADDRESS,PHONE,TRANSFORMER,GISID,MOVEINDATE,METERNUM,GIS_RWO_ID3)
      VALUES (OMS.PO_NOTIFICATION_CUST_seq.nextval,oms.po_notification_task_seq.currval,c.FEEDERNAME,c.CUSTOMERTYPE,c.NMI,c.NAME,c.SERVICEADDRESS,c.POSTALADDRESS,c.PHONE,c.TRANSFORMER,c.GISID,c.MOVEINDATE,c.METERNUM,c.GIS_RWO_ID3 );
   end loop;


END LOOP;

UPDATE oms.po_notification_header h  SET h.parent_project_id = v_new_project_id  WHERE h.id = v_source_project_id;

END;


/*=============================================================================
Creates the XML document for the retailer Notification
Stored in the table PO_NOTIFICATION_RETAILER_LOG.xml_doc

*/
PROCEDURE publish_retailer_notifications
(
   p_customer_pub_id IN number
 , p_publish_Date IN Date
)
IS
c_func_name  constant varchar2(32) not null := 'publish_retailer_notifications';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;

l_publishDate date;
l_insert_sqlcount PLS_INTEGER := 0;
l_xmldoc xmltype;


BEGIN
   l_publishDate := trunc(p_publish_Date);

   logger.append_param(l_params, 'l_publishDate', l_publishDate);
   logger.log('START{', l_scope,null,l_params );
   debug_pkg.printf ('%1: START{ %2=%3',l_scope, 'l_publishDate' ,to_char(l_publishDate, 'YYYY-MM-DD') );

   l_publishDate := trunc(p_publish_Date);
   

   insert into  PO_NOTIFICATION_RETAILER_LOG(pon_publish_id,retailer_name,date_publish,xml_doc)
   SELECT  p_customer_pub_id,
    a.retailer_name,
    l_publishDate,
          (SELECT                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      --{
                 XMLROOT (XMLELEMENT ("pon_retailer_messages",
                                      xmlattributes (gc_xml_version AS "version", TO_CHAR (SYSDATE, 'yyyy-mm-dd"T"hh24:mi":00"') AS "datetimestamp", TO_CHAR (l_publishDate, 'yyyy-mm-dd') AS "date_publish"),
                                      XMLELEMENT ("email", a.po_rpt_email_address),
                                      XMLELEMENT ("retailer_name", a.retailer_name),
                                      XMLELEMENT ("file_prefix", a.po_rpt_file_prefix),
                                      XMLELEMENT ("nmi_list",
                                                  XMLAGG (XMLELEMENT ("nmi",
                                                                      xmlattributes (pnp.notification_task_id AS "task_id",
                                                                                     notification_desc as "notification_desc",
                                                                                     service_address AS "service_address",
                                                                                     customer_name AS "customer_name",
                                                                                     TO_CHAR (outage_window_start, 'yyyy-mm-dd"T"hh24:mi":00"') AS "start",
                                                                                     TO_CHAR (outage_window_end, 'yyyy-mm-dd"T"hh24:mi":00"') AS "end"),
                                                                      nmi)))),
                          VERSION '1.0',
                          STANDALONE YES)
             FROM PO_NOTIFICATION_PUBLISH_last pnp
                  JOIN po_retailer pr ON PNP.RETAILER_NO_LEGAL_ENTITY = PR.NO_LEGAL_ENTITY AND PNP.CD_COMPANY_SYSTEM = PR.CD_COMPANY_SYSTEM
                  JOIN po_retailer_contact prc ON PRC.RETAILER_NAME = PR.RETAILER_NAME
            WHERE prc.po_rpt_email_address IS NOT NULL AND po_rpt_sending_method = 'EMAIL' AND prc.retailer_name = a.retailer_name and pnp.notification_type <> gc_NotifTypeCustom )
             xml                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       --}
     FROM (  SELECT DISTINCT prc.retailer_name, prc.po_rpt_file_prefix, prc.po_rpt_email_address
               FROM PO_NOTIFICATION_PUBLISH_last pnp
                    JOIN po_retailer pr ON PNP.RETAILER_NO_LEGAL_ENTITY = PR.NO_LEGAL_ENTITY AND PNP.CD_COMPANY_SYSTEM = PR.CD_COMPANY_SYSTEM
                    JOIN po_retailer_contact prc ON PRC.RETAILER_NAME = PR.RETAILER_NAME
              WHERE prc.po_rpt_email_address IS NOT NULL AND po_rpt_sending_method = 'EMAIL'
           ORDER BY prc.po_rpt_file_prefix) a
   ;

   l_insert_sqlcount := SQL%ROWCOUNT;
   logger.log_information ( l_insert_sqlcount || ' row(s) inserted to ' || 'PO_NOTIFICATION_RETAILER_LOG id=' || p_customer_pub_id, l_scope,null,l_params );

   debug_pkg.printf ('%1: END} %2=%3',l_scope, 'l_publishDate', to_char(l_publishDate, 'YYYY-MM-DD') );
   logger.log('END}', l_scope,null,l_params );
END publish_retailer_notifications;

/*=============================================================================
Creates the XML document containing the Customer Outage used by the fulfilment contractor
to print the notices.
Stores xml in table PO_NOTIFICATION_PUBLISH_LOG.xml_doc
CR32967-PlannedOutage-Lifesupport publish date defaults to yesterday
*/
PROCEDURE publish_fullfilment_notices
(
   p_PublishId_out out number
 , p_publish_Date IN Date DEFAULT SYSDATE - 1
)
IS
pragma autonomous_transaction;
c_func_name  constant varchar2(32) not null := 'Publish_Fullfilment_Notices';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;

l_publishDate date;
l_insert_sqlcount PLS_INTEGER := 0;
l_update_sqlcount PLS_INTEGER := 0;
l_xmldoc xmltype;
l_publishId number(10) ;
l_already number(1) := 0;
v_app         number;

BEGIN
   logger.append_param(l_params, 'l_publishDate', l_publishDate);
   p_PublishId_out := 0;
   l_publishDate := trunc(p_publish_Date);

   logger.log('START{', l_scope,null,l_params );
   debug_pkg.printf ('%1: START{ %2=%3',l_scope, 'l_publishDate', to_char(l_publishDate, 'YYYY-MM-DD') );

   v_app := oms.ched_log_utils.start_application('PON_PUBLISH_FULFILLMENT', 'Start');

-- Raise exception if already published today
begin
   select 1 into l_already from dual
   where exists (select 1 from PO_NOTIFICATION_PUBLISH_LOG a  where trunc(A.DATE_PUBLISH) = trunc(l_publishDate));
EXCEPTION
when no_data_found then
   l_already := 0;
when others then
   raise;
end;

if l_already > 0 then
   logger.log_warning('Planned Outage Notification "Publish Fulfilment Notices" has been run today',l_scope,null,l_params);
   raise_application_error(errnum_pon_publish_run_today, 'Planned Outage Notification "Publish Fulfilment Notices" has been run today');
end if;


    get_PlanOutPublishNMIs(l_publishDate);
    get_CustomerDetails;

select
 XMLROOT(XMLELEMENT("pon_customer_messages",
    xmlattributes (gc_xml_version AS "version", TO_CHAR (SYSDATE, 'yyyy-mm-dd"T"hh24:mi":00"') AS "datetimestamp", TO_CHAR (l_publishDate, 'yyyy-mm-dd') AS "date_publish" )
   ,xmlconcat(
     xmlagg(
     XMLCONCAT(XMLELEMENT("pon_message"
    ,XMLATTRIBUTES( delivery_method     as "delivery_method"  )
    ,xmlelement("customer_name",a.customer_name    )
    ,xmlelement("customer_postal_address",a.customer_postal_address    )
    --[
    ,(select XMLforest (
   xmlagg(
        xmlelement("nmi",
                  xmlattributes(
              nmi                                                      as "id"
             ,project_id                                               as "pon_project_id"
             ,notification_task_id                                     as "pon_task_id"
             ,retailer_no_legal_entity                                 as "retailer_no_legal_entity"
             ,retailer_name                                            as "retailer_name"
             ,cis_no_account                                           as "cis_no_account"
             ,cd_company_system                                        as "company"
             ,service_address                                          as "service_address"
             ,is_life_support                                          as "is_life_support"
             ,notification_type                                        as "notification_type"
             ,notification_desc                                        as "notification_desc"
             ,to_char(outage_window_start,'yyyy-mm-dd"T"hh24:mi":00"') as "outage_window_start"
             ,to_char(outage_window_end,  'yyyy-mm-dd"T"hh24:mi":00"') as "outage_window_end"
          ),
         nmi) order by nmi)
         "nmi_list" )
        from PO_NOTIFICATION_PUBLISH_LAST pnp where pnp.customer_name = a.customer_name and pnp.customer_postal_address = a.customer_postal_address and PNP.Delivery_method = a.delivery_method
        )
    --]
    ) )
    )
  )
    )  ,  VERSION '1.0',  STANDALONE YES)
xml_doc  into l_xmldoc
from
(
select customer_name , customer_postal_address, delivery_method from
oms.PO_NOTIFICATION_PUBLISH_LAST
group by customer_name , customer_postal_address, delivery_method
order by 1,2
) a
;


   INSERT INTO PO_NOTIFICATION_PUBLISH_LOG (DATE_PUBLISH ,XML_DOC) values (l_publishDate,l_xmldoc) returning id into l_publishId;

   l_insert_sqlcount := SQL%ROWCOUNT;
   logger.log_information(l_insert_sqlcount || ' row(s) inserted to ' || 'PO_NOTIFICATION_PUBLISH_LOG id=' || l_publishId ,l_scope,null,l_params);

   -- Retailer Notifications
   publish_retailer_notifications(l_publishId, l_publishDate);

   --UPDATE the publish date now we are done
   UPDATE po_customer_notification_log pcnl SET date_sent = l_publishDate where date_requested = l_publishDate;

   commit;
   p_PublishId_out := l_publishId;
   oms.ched_log_utils.end_application(v_app, 'success',l_update_sqlcount || ' Customer interuptions Notified' );
   debug_pkg.printf ('%1: END} %2=%3',l_scope, 'l_publishDate', to_char(l_publishDate, 'YYYY-MM-DD') );
   logger.log_information(printf ('SUCCESS:%2=%3 ',l_scope, 'l_publishDate', to_char(l_publishDate, 'YYYY-MM-DD')) , l_scope, null,l_params );
   logger.log('END}', l_scope,null,l_params );
EXCEPTION
    WHEN OTHERS THEN
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);

   logger.log_error(
          p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         --,p_params  => l_params
         );

RAISE;
end Publish_Fullfilment_Notices;



/*
Gets the Planned Outage Notice details for date p_publish_Date

Commits the results to oms.po_notification_publish_last
*/
procedure get_PlanOutPublishNMIs
(
p_publish_Date IN Date
)
is PRAGMA autonomous_Transaction;
c_func_name  constant varchar2(32) not null := 'get_PlanOutPublishNMIs';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;

l_publishDate date;
l_insert_sqlcount PLS_INTEGER := 0;
l_action_desc VARCHAR2(80);
BEGIN
  l_publishDate := trunc(p_publish_Date);
  logger.append_param(l_params, 'l_publishDate', l_publishDate);
  logger.log('START{', l_scope,null,l_params );
  debug_pkg.printf ('%1: START{ %2=%3',l_scope, 'l_publishDate' ,to_char(l_publishDate, 'YYYY-MM-DD') );

  l_action_desc :=  'Truncating PO_NOTIFICATION_PUBLISH_LAST';
  logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
  EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || c_pubNmis_tab_name || ' DROP STORAGE' ;
  logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


  l_action_desc :=  'Populating PO_NOTIFICATION_PUBLISH_LAST';
  logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
INSERT /* + APPEND  */  INTO
   oms.po_notification_publish_last
    (
     ID ,PROJECT_ID ,NOTIFICATION_TASK_ID ,OUTAGE_WINDOW_START ,OUTAGE_WINDOW_END ,ACCOUNT_NO ,        CIS_NO_ACCOUNT ,NOTIFICATION_TYPE  ,DELIVERY_METHOD ,DATE_REQUESTED ,NMI
    )
   SELECT
    ID ,PROJECT_ID, NOTIFICATION_TASK_ID  ,START_TIME          ,END_TIME          ,ACCOUNT_NO ,null as CIS_NO_ACCOUNT ,NOTIFICATION_TYPE  ,MAIL_INDICATOR  ,DATE_REQUESTED ,NMI
   FROM PO_CUSTOMER_NOTIFICATION_LOG a
  WHERE DATE_REQUESTED = l_publishDate;
   l_insert_sqlcount := SQL%ROWCOUNT;
   COMMIT;

   logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );
   logger.log_information(printf ('SUCCESS:%2=%3  Nmi Count=%4',l_scope, 'l_publishDate', to_char(l_publishDate, 'YYYY-MM-DD') ,l_insert_sqlcount) , l_scope, null,l_params );
   logger.log('END}', l_scope,null,l_params );
EXCEPTION
    WHEN OTHERS THEN
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);

   logger.log_error(
          p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         --,p_params  => l_params
         );

RAISE;
end get_PlanOutPublishNMIs;


--=============================================================================
function get_CISCustomerDetails return pls_integer
is PRAGMA autonomous_Transaction ;
/*
Updates PO_NOTIFICATION_PUBLISH_LAST with the latest CIS customer details from the CIS replicated tables
Uses a row by row approach because of
ORA-01555: snapshot too old: rollback segment number 9 with name "_SYSSMU9_2978212222$" too small
issues found in POND and PONT for the nmis 62032097878,62037580250
*/
c_func_name  constant varchar2(32) not null := 'get_CISCustomerDetails';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;
l_insert_sqlcount pls_integer :=0;
l_action_desc VARCHAR2(80);

l_rowsdonecount pls_integer :=0;

CURSOR cur_cis_cust(nmi_in VARCHAR2) IS
 select 
     CIS_ACCOUNT_NUMBER
    ,LEGAL_ENTITY_NAME
    ,CD_COMPANY_SYSTEM
    ,LOCATION_DESC
    ,LEGAL_ENTITY_ID
    ,NO_PROPERTY
    ,ACCOUNT_NUMBER
    ,POSTAL_ADDRESS
    from ched_cis_aggregated_data cis_cust
    WHERE  cis_cust.premise_number = nmi_in;

CURSOR cur_pon_cust IS
SELECT  
 NMI
,CIS_NO_ACCOUNT              
,customer_name              
,cd_company_system          
,service_address            
,customer_legal_entity_id   
,no_property                
,ACCOUNT_NO                 
,gis_id                     
,customer_postal_address
FROM PO_NOTIFICATION_PUBLISH_LAST order by nmi for update;

BEGIN
   logger.log('START{', l_scope);
   l_action_desc :=  'Get CIS Customer Details keyed on nmi';

    FOR r_poncust IN cur_pon_cust LOOP
        l_rowsdonecount := l_rowsdonecount +1;
        IF (MOD( l_rowsdonecount, 100) = 0) THEN logger.log(printf ('Doing: %1 done:%2', l_action_desc,l_rowsdonecount) , l_scope, null,l_params );        END IF;
        begin
        <<cis_customers>>
        FOR r_cis  IN  cur_cis_cust(r_poncust.nmi ) LOOP
            UPDATE PO_NOTIFICATION_PUBLISH_LAST
                SET
                    CIS_NO_ACCOUNT             = r_cis.CIS_ACCOUNT_NUMBER
                   ,customer_name              = r_cis.LEGAL_ENTITY_NAME
                   ,cd_company_system          = r_cis.CD_COMPANY_SYSTEM
                   ,service_address            = r_cis.LOCATION_DESC
                   ,customer_legal_entity_id   = r_cis.LEGAL_ENTITY_ID
                   ,no_property                = r_cis.NO_PROPERTY
                   ,ACCOUNT_NO                 = r_cis.ACCOUNT_NUMBER
                   ,gis_id                     = r_cis.ACCOUNT_NUMBER
                   ,customer_postal_address    = r_cis.POSTAL_ADDRESS
              WHERE CURRENT OF cur_pon_cust;
              exit cis_customers;
       END LOOP cis_customers;
       EXCEPTION 
           WHEN OTHERS THEN
           logger.log_error(printf ('Doing: %1 nmi=%3 done:%2', l_action_desc,l_rowsdonecount,r_poncust.nmi) , l_scope, null,l_params );
           debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);
           logger.log_error(
             p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
            ,p_scope   => l_scope
           ,p_params  => l_params
           );
       END;
    END LOOP;
    commit;
   logger.log('END}', l_scope);
   return(l_rowsdonecount);
EXCEPTION
    WHEN OTHERS THEN
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);
      logger.log_error(
          p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         ,p_params  => l_params
         );
    RAISE;
END get_CISCustomerDetails;

--=============================================================================
PROCEDURE get_CustomerDetails
IS
/*
Updates PO_NOTIFICATION_PUBLISH_LAST with the latest customer details
from the CIS replicated tables
*/
c_func_name  constant varchar2(32) not null := 'get_CustomerDetails';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;
l_insert_sqlcount pls_integer :=0;
l_action_desc VARCHAR2(80);

BEGIN
   --logger.append_param(l_params, 'p_param1_in', p_param1_in);
   logger.log('START{', l_scope);

   l_action_desc :=  'Get CIS Customer Details keyed on nmi';
   logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );

    l_insert_sqlcount := get_CISCustomerDetails;

/* For some unexplained reason in PONT and POND for the NMI 62032097878,62037580250
this query fails with ORA-01555: snapshot too old: rollback segment number 9 with name "_SYSSMU9_2978212222$" too small
The query succeeds in PONP and PONU
   update PO_NOTIFICATION_PUBLISH_LAST pnpl
     set (
     CIS_NO_ACCOUNT
    ,customer_name
    ,cd_company_system
    ,service_address
    ,customer_legal_entity_id
    ,no_property
    ,ACCOUNT_NO
    ,gis_id
    ,customer_postal_address
    )=(
    select 
     CIS_ACCOUNT_NUMBER
    ,LEGAL_ENTITY_NAME
    ,CD_COMPANY_SYSTEM
    ,LOCATION_DESC
    ,LEGAL_ENTITY_ID
    ,NO_PROPERTY
    ,ACCOUNT_NUMBER as account_no
    ,ACCOUNT_NUMBER as gis_id
    ,POSTAL_ADDRESS
    from ched_cis_aggregated_data ccadl
    where ccadl.premise_number = pnpl.nmi and rownum=1);
    l_insert_sqlcount := SQL%ROWCOUNT;
    
*/
   logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );

    l_action_desc :=  'Update the life support based on Property No';
    logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
    update PO_NOTIFICATION_PUBLISH_LAST pnpl
    set (is_life_support)=(
    NVL((select
    'TRUE' AS is_life_support
    from CIS_LIFE_SUPPORT cls
    where pnpl.NO_PROPERTY=cls.NO_PROPERTY and pnpl.cd_company_system = cls.cd_company_system and cls.CD_SPEC_COND_TP = 'LIFE' and rownum=1 ),'FALSE'))
    where CIS_NO_ACCOUNT is not null;
    l_insert_sqlcount := SQL%ROWCOUNT;
    logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


    l_action_desc :=  'update the Planned Outage details';
    logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
    update PO_NOTIFICATION_PUBLISH_LAST pnpl
    set (notification_desc) = (
    select pne.DESCRIPTION from PO_NOTIFICATION_TYPE pne where pne.CODE = pnpl.NOTIFICATION_TYPE);
    l_insert_sqlcount := SQL%ROWCOUNT;
    logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


    l_action_desc :=  'Update the retailer legal_entity no based on NMI';
    logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
    update PO_NOTIFICATION_PUBLISH_LAST pnpl
    set (retailer_no_legal_entity) = (
    select
     max(t036.NO_LEGAL_ENTITY)  /* to guard against ORA-01427 single-row subquery returns more than one row due to data error */
    from
    TVP056SERVPROV      t056
    left join TVP054SERVPROVRESP  t054   on t056.NO_PROPERTY = t054.NO_PROPERTY    and t056.NO_PROPERTY = t054.NO_PROPERTY and t056.NO_SERV_PROV = t054.NO_SERV_PROV  and t054.DT_END is null and t056.CD_COMPANY_SYSTEM = t054.CD_COMPANY_SYSTEM
    left join TVP024CUSTACCTROLE  t024   on t054.NO_ACCOUNT = t024.NO_ACCOUNT and t024.TP_CUST_ACCT_ROLE = 'P'   and t056.CD_COMPANY_SYSTEM = t024.CD_COMPANY_SYSTEM
    left join tvp036legalentity   t036   on t024.NO_LEGAL_ENTITY = t036.NO_LEGAL_ENTITY and t056.CD_COMPANY_SYSTEM = t036.CD_COMPANY_SYSTEM
    where t056.TXT_NAT_SUPP_POINT = pnpl.nmi and rownum=1
    )
    where  CIS_NO_ACCOUNT is not null;
    l_insert_sqlcount := SQL%ROWCOUNT;
    logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


    l_action_desc :=  'Update the retailer translated name';
    logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
    update PO_NOTIFICATION_PUBLISH_LAST pnpl
    set (retailer_name)=(
    select distinct pr.retailer_name
    from oms.po_retailer pr where pr.NO_LEGAL_ENTITY = pnpl.Retailer_no_legal_entity AND pnpl.cd_company_system = pr.cd_company_system and rownum=1
    )
    where  CIS_NO_ACCOUNT is not null;
    l_insert_sqlcount := SQL%ROWCOUNT;
    logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


    /* Get the Not quite right customers (NQR) customers details*/

    l_action_desc :=  'Get the NQR service address by nmi from tvp046property';
    logger.log_information(printf ('Attempting: %1', l_action_desc) , l_scope, null,l_params );
    update PO_NOTIFICATION_PUBLISH_LAST pnpl
    set (
     cis_no_account
    ,customer_name
    ,customer_postal_address
    ,service_address
    ,is_life_support
    ,CD_COMPANY_SYSTEM
    )=(
    select
     null
    ,'The Occupant'
    ,tad.formatted_address
    ,tad.formatted_address
    ,'FALSE'
    ,tad.CD_COMPANY_SYSTEM
    from TVP056SERVPROV sp
    JOIN tvp046property prop ON sp.cd_company_system = prop.cd_company_system AND prop.no_property = sp.no_property
    JOIN ched_cis_address tad ON sp.cd_company_system = tad.cd_company_system AND prop.cd_address = tad.cd_address
    where sp.txt_nat_supp_point = pnpl.NMI
    )
    where cis_no_account is null;
    l_insert_sqlcount := SQL%ROWCOUNT;
    logger.log_information(printf ('Done: %1, SQL%ROWCOUNT=%2',l_action_desc,l_insert_sqlcount ) , l_scope, null,l_params );


   logger.log('END}', l_scope);
EXCEPTION
    WHEN OTHERS THEN
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);
      logger.log_error(
          p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         ,p_params  => l_params
         );
    RAISE;
END get_CustomerDetails;



/*=============================================================================
Create one destination per Planned Outage Notification Project */

function create_po_destination
(
    p_project_id_in     IN po_notification_header.id%type
   ,p_destination_id_in IN POWERON.PO_DESTINATION.ID%type
)
RETURN poweron.po_destination.ID%TYPE
IS
c_func_name  constant varchar2(32) not null := 'create_po_destination';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;
l_destination_id_out po_notification_header.id%TYPE := NULL;
l_order_id           po_notification_header.order_id%type;
l_sqlcount           pls_integer :=0;

BEGIN

   logger.append_param(l_params, 'p_project_id_in', p_project_id_in);
   logger.append_param(l_params, 'p_destination_id_in', p_destination_id_in);

MERGE INTO POWERON.PO_DESTINATION d
USING (
   select
     h.id                  as project_id
   , h.order_id            as order_id
   , poieb.id              as int_elec_break_id
   , poieb.dataset_name    as DATASET_NAME
   , poieb.rwo_code        as GIS_RWO_CODE
   , poieb.rwo_id1         as GIS_RWO_ID1
   , poieb.rwo_id2         as GIS_RWO_ID2
   , poieb.rwo_id3         as GIS_RWO_ID3
   , poieb.main_world_x    as X
   , poieb.main_world_y    as Y
   , poieb.description     as DESCRIPTION
   , poieb.location_desc   as LOCATION_DESC
   , p_destination_id_in   as po_destination_id
   from
   oms.po_notification_header h
   join poweron.po_int_elec_break poieb on H.INTERRUPTED_GIS_RWO_ID3 = POIEB.RWO_ID3 and POIEB.BUILD_VERSION  ='master'
   where
   h.id = p_project_id_in
  ) s
ON
  (d.ID = s.po_destination_id)
WHEN MATCHED
THEN
UPDATE SET
  d.DATASET_NAME = s.DATASET_NAME,
  d.GIS_RWO_CODE = s.GIS_RWO_CODE,
  d.GIS_RWO_ID1 = s.GIS_RWO_ID1,
  d.GIS_RWO_ID2 = s.GIS_RWO_ID2,
  d.GIS_RWO_ID3 = s.GIS_RWO_ID3,
  d.X = s.X,
  d.Y = s.Y,
  d.DESCRIPTION = s.DESCRIPTION,
  d.LOCATION_DESC = s.LOCATION_DESC
WHEN NOT MATCHED
THEN
INSERT (
                               ID, DATASET_NAME,   GIS_RWO_CODE,   GIS_RWO_ID1,   GIS_RWO_ID2,   GIS_RWO_ID3,   X,   Y,   DESCRIPTION,   LOCATION_DESC)
VALUES (
    po_destination_seq.NEXTVAL, s.DATASET_NAME, s.GIS_RWO_CODE, s.GIS_RWO_ID1, s.GIS_RWO_ID2, s.GIS_RWO_ID3, s.X, s.Y, s.DESCRIPTION, s.LOCATION_DESC)
;

    l_sqlcount := SQL%ROWCOUNT;
   debug_pkg.printf('%1: MERGE POWERON.PO_DESTINATION: SQL%ROWCOUNT=%2',l_scope, l_sqlcount);

   FOR r  IN destination_details_cur(p_project_id_in) LOOP
      l_destination_id_out := r.po_destination_id;
      l_order_id := r.order_id;
   END LOOP;

   UPDATE poweron.po_order po SET po.main_destination_id = l_destination_id_out WHERE po.id = l_order_id ;
   l_sqlcount := SQL%ROWCOUNT;
   debug_pkg.printf('%1: UPDATE:poweron.po_order: SQL%ROWCOUNT=%2',l_scope, l_sqlcount);
   debug_pkg.printf('%1: OUT:destination_id=%2',l_scope, l_destination_id_out);

   logger.log(p_text => printf('SUCCESS: po_destination rows: SQL%ROWCOUNT=%1 order_id=%2',l_sqlcount,l_order_id), p_params  => l_params, p_scope   => l_scope);
   RETURN l_destination_id_out;
END create_po_destination;



/*=============================================================================
Request Destination */

PROCEDURE create_po_request_destination
(
   p_project_id_in IN po_notification_header.id%type
)
IS
c_func_name  constant varchar2(32) not null := 'create_po_request_destination';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;
l_destination_id_out po_notification_header.id%TYPE := NULL;

l_order_id po_notification_header.order_id%type;
l_sqlcount pls_integer :=0;

BEGIN
   logger.append_param(l_params, 'p_project_id_in', p_project_id_in);


   MERGE INTO POWERON.PO_REQUEST_DESTINATION d
   USING (
   select
        h.id                  as project_id
      , o.id                  as order_id
      , o.request_id          as request_id
      , o.main_destination_id as destination_id
      , 'work_location'       as "TYPE"
      , null                  as phase
      , null                  as extra_info
      from
      oms.po_notification_header h
      join poweron.po_order o   on h.order_id   = o.id
      join poweron.po_request r on o.request_id = r.id
      where
      h.id = p_project_id_in
   ) s
   ON
     (d.REQUEST_ID = s.REQUEST_ID and d.DESTINATION_ID = s.DESTINATION_ID)
   WHEN MATCHED
   THEN
   UPDATE SET
     d.TYPE = s.TYPE,
     d.PHASE = s.PHASE,
     d.EXTRA_INFO = s.EXTRA_INFO
   WHEN NOT MATCHED
   THEN
   INSERT (
     REQUEST_ID, DESTINATION_ID, TYPE, PHASE, EXTRA_INFO)
   VALUES (
     s.REQUEST_ID, s.DESTINATION_ID, s.TYPE,  s.PHASE, s.EXTRA_INFO);

   l_sqlcount := SQL%ROWCOUNT;
   debug_pkg.printf('%1: merge poweron.po_request_destination rows: SQL%ROWCOUNT=%2',l_scope, l_sqlcount);
   logger.log(p_text => printf('merge poweron.po_request_destination rows: SQL%ROWCOUNT=%1',l_sqlcount), p_params  => l_params, p_scope   => l_scope);

END create_po_request_destination;



/*=============================================================================
Update the order so we can use goto in PowerOn
 */

PROCEDURE update_po_order
(
    p_project_id_in IN po_notification_header.id%type
   ,p_destination_id_in IN POWERON.PO_DESTINATION.ID%type
)
IS
c_func_name  constant varchar2(32) not null := 'update_po_order';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;
l_destination_id_out po_notification_header.id%TYPE := NULL;

l_order_id po_notification_header.order_id%type;
l_sqlcount pls_integer :=0;
c_boundBox constant pls_integer := 20000;
BEGIN

   logger.append_param(l_params, 'p_project_id_in', p_project_id_in);
   logger.append_param(l_params, 'p_destination_id_in', p_destination_id_in);

-- PO430 change. Field feeders does not longer exist.
update poweron.po_order po
--set(feeder,location_desc,simple_area_id,comments,min_x,min_y,max_x,max_y )  =( select
--     h.feeders
set(location_desc,simple_area_id,comments,min_x,min_y,max_x,max_y )  =( select
     poieb.location_desc   as location_desc
-- End PO430 change.
   , poieb.simple_area_id  as simple_area_id
   , substr(printf( to_char(sysdate,'yyyy-mm-dd"T"hh24:mi')||
  ': [Notification Id]:%1 [Outage Date]:%2 [Prj Manager]:%3 [Applicant Name]:%4  [Customers Out]:%5 [Device description]:%6 [Order]:%7 [Order Id]:%8 [Feeders]:%9'
  , h.project_id
  , H.OUTAGE_DATE
  , H.PROJECT_MANAGER_NAME
  , H.APPLICANT_NAME
  , h.customer_count
  , h.LOC_DESC
  , H.ORDER_REF_LABEL
  , h.order_id
  , h.feeders
  ),1,500) as Comments
   , d.x - c_boundBox
   , d.y - c_boundBox
   , d.x + c_boundBox
   , d.y + c_boundBox
   from
   oms.PO_NOTIFICATION_PROJ_SUMMARY h
   join poweron.po_int_elec_break poieb on H.INTERRUPTED_GIS_RWO_ID3 = POIEB.RWO_ID3 and POIEB.BUILD_VERSION  ='master'
   join po_destination d on D.GIS_RWO_ID3 = POIEB.RWO_ID3 and d.id = p_destination_id_in
   where
   po.id = h.order_id
   and h.project_id = p_project_id_in
   )
where po.id = (select order_id from PO_NOTIFICATION_HEADER h where h.id = p_project_id_in);

-- PO430 change.
update poweron.po_order_ui_fields po
set(current_feeders)  =( select
     h.feeders
   from
   oms.PO_NOTIFICATION_PROJ_SUMMARY h
   join poweron.po_int_elec_break poieb on H.INTERRUPTED_GIS_RWO_ID3 = POIEB.RWO_ID3 and POIEB.BUILD_VERSION  ='master'
   join po_destination d on D.GIS_RWO_ID3 = POIEB.RWO_ID3 and d.id = p_destination_id_in
   where
   po.order_id = h.order_id
   and h.project_id = p_project_id_in
   )
where po.order_id = (select order_id from PO_NOTIFICATION_HEADER h where h.id = p_project_id_in);
-- End PO430 change.
   l_sqlcount := SQL%ROWCOUNT;
   debug_pkg.printf('%1: update poweron.po_order rows: SQL%ROWCOUNT=%2',l_scope, l_sqlcount);
   logger.log(p_text => printf('update poweron.po_order rows: SQL%ROWCOUNT=%1',l_sqlcount), p_params  => l_params, p_scope   => l_scope);

END update_po_order;


/*=============================================================================
Call after Successful Ordering of Planned Outage Project

If there is no Order returns success

Be careful to only create 1 of
   po_destination
   po_request_destination
when an PON Project is Ordered multiple times.

Assumptions
   The Order and associated Request exists

-- Step 1 MERGE po_destination record

-- Step 2 MERGE po_request_destination record

-- Step 3 UPDATE po_order

all based on the select * from poweron.po_int_elec_break poieb where POIEB.ID = PO_NOTIFICATION_PROJ_SUMMARY.interrupted_device


*/
PROCEDURE update_PowerOnOrder
(
   p_project_id_in IN PO_NOTIFICATION_HEADER.ID%type
)
IS
c_func_name  constant varchar2(32) not null := 'update_PowerOnOrder';
l_scope  logger_logs.scope%type := gc_scope_prefix || c_func_name;
l_params logger.tab_param;

-- PON Project of type cancelled don't need to set the destination
cursor proj_cur(p_project_id PO_NOTIFICATION_HEADER.ID%type) is
select
h.id
,h.interrupted_gis_rwo_id3
,h.order_id
,po.main_destination_id
from oms.po_notification_header h
join poweron.po_order po on PO.ID = H.ORDER_ID
where
not exists (select 1 from PO_NOTIFICATION_TASK t where t.notification_type = 'CAN' and H.ID = t.notification_header_id)
and h.id = p_project_id;


l_destination_id po_notification_header.id%TYPE := NULL;

BEGIN
   logger.append_param(l_params, 'p_project_id_in', p_project_id_in);

   logger.log('START{', l_scope,null,l_params );
   debug_pkg.printf ('%1: START{ %2=%3',l_scope, 'p_project_id_in', p_project_id_in );

FOR r IN proj_cur(p_project_id_in) LOOP
   debug_pkg.printf ('%1: %2=%3 %4=%5 %6=%7',l_scope,
      'r.id',r.id,
      'r.interrupted_gis_rwo_id3', r.interrupted_gis_rwo_id3,
      'r.main_destination_id',r.main_destination_id);
   --Step 1

   l_destination_id := create_po_destination( p_project_id_in, r.main_destination_id  );
   logger.log(printf('po_destination create/update before:%1 after:%2',r.main_destination_id , l_destination_id), l_scope,null,l_params );

   --Step 2
   create_po_request_destination(p_project_id_in );

   --Step 3
   update_po_order( p_project_id_in, l_destination_id);

END LOOP;

   debug_pkg.printf ('%1: END} %2=%3',l_scope, 'p_project_id_in', p_project_id_in );
   logger.log('END}', l_scope,null,l_params );
EXCEPTION
    WHEN OTHERS THEN
      debug_pkg.printf( 'Unhandled Exception %1:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE, l_scope);

   logger.log_error(
          p_text   =>  'Unhandled Exception:' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
         ,p_scope   => l_scope
         ,p_params  => l_params
         );

RAISE;
end update_PowerOnOrder;


--==============================================================================
PROCEDURE init
IS
   /* Initialise the parameter the package relies on*/
c_func_name CONSTANT VARCHAR2(32) NOT NULL := 'Init';
l_scope logger_logs.scope%type := gc_scope_prefix || c_func_name;

BEGIN

   logger.log('Initialising Package ',l_scope);
   BEGIN
      BEGIN
         for r in m_settings_cur loop
              m_settings := r;
         end loop;
         IF m_settings.debug_pkg = 'ON' THEN debug_pkg.debug_on; ELSE debug_pkg.debug_off;END IF;
      EXCEPTION
         WHEN OTHERS THEN
            debug_pkg.debug_on;
      END;

   EXCEPTION
      WHEN OTHERS THEN
         debug_pkg.debug_on;
   END;

   c_days_in_past_expired := to_number(m_settings.days_in_past_expired);
   c_past_days_recent := to_number(m_settings.past_days_recent);

   debug_pkg.printf( $$plsql_unit || ' - Package Initialisation  = %1', l_scope);

 EXCEPTION
   WHEN OTHERS THEN
      logger.log_error(
         p_text   =>  'Exception: Initialisation failed. ' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE
        ,p_scope   => l_scope
    );

 RAISE;
END init;



--==============================================================================

-- Initialization section
BEGIN
   init;
EXCEPTION
  WHEN OTHERS THEN
    logger.LOG_ERROR ( 'Exception: ' || dbms_utility.format_error_stack || chr(10) || dbms_utility.FORMAT_ERROR_BACKTRACE,m_settings.debug_pkg);
    RAISE;

END PLANNED_OUTAGE;
/


