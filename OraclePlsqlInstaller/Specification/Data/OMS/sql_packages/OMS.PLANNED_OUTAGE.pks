
  CREATE OR REPLACE PACKAGE "OMS"."PLANNED_OUTAGE" AS
--============================================================================
/*

    Project : GIS/OMS

Applic Name : Planned Outages

     Author : russell

       Date : 2016-07-11

Copyright (c) Ched Services

  Function : Planned Network Outages application suite

Discussion :


===========================================================================*/
--
--PUBLIC Procedures
--
errnum_pon_publish_run_today constant integer := -20996;
pon_publish_run_today   EXCEPTION;
PRAGMA EXCEPTION_INIT (pon_publish_run_today, -20996);



FUNCTION getVersion return varchar2;
Procedure status ;

PROCEDURE REMOVE_OLD_NOTICES;


PROCEDURE PO_CLONE_TASK_DEV_CUST
(
 v_new_project_id         IN  NUMBER   --is the new project which already exists
,v_source_project_id      IN NUMBER    --is the project to clone the tasks, devices, customers
);

procedure publish_retailer_notifications
(
   p_customer_pub_id IN number
 , p_publish_Date IN Date
);

PROCEDURE publish_fullfilment_notices
(
   p_PublishId_out out number
 , p_publish_Date IN Date DEFAULT SYSDATE - 1
);

PROCEDURE update_PowerOnOrder
(
      p_project_id_in IN PO_NOTIFICATION_HEADER.ID%type
);

procedure get_PlanOutPublishNMIs
(
p_publish_Date IN Date
);

PROCEDURE get_CustomerDetails;


END PLANNED_OUTAGE;
/


