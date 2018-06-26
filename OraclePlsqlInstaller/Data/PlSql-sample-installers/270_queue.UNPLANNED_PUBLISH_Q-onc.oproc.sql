/*===========================================================================

    Project : GIS/OMS

Applic Name : AppName

     Author : Russell

       Date : 2015-03-03

       Comment

===========================================================================*/


define JOB_NAME=UNPLANNED_PUBLISH_JOB
define QUEUE_NAME=UNPLANNED_PUBLISH_Q
define QUEUE_TABLE_NAME=UNPLANNED_PUBLISH_TAB

define

@ sql_helper/scheduler_remove.sql &JOB_NAME.


-- Stop the event queue.

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
   DBMS_AQADM.stop_queue (queue_name => '&QUEUE_NAME.');
EXCEPTION
  WHEN OTHERS THEN
   NULL;
--    IF SQLCODE = -24010 THEN
--      SQLSTR := 'SELECT COUNT(*) from user_queues where name = ''&QUEUE_NAME.'' ';
--      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
--      IF TEMP_COUNT = 0 THEN RETURN;
--      ELSE RAISE;
--      END IF;
--    ELSE
--      RAISE;
--    END IF;
END;
/


DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR := '';
  DBMS_AQADM.stop_queue (queue_name => 'AQ$&QUEUE_NAME._TABLE_E');
EXCEPTION
  WHEN OTHERS THEN
     NULL;
--    IF SQLCODE = -24010 THEN
--      SQLSTR := 'SELECT COUNT(*) from user_queues where name = ''AQ$&QUEUE_NAME._TABLE_E'' ';
--      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
--      IF TEMP_COUNT = 0 THEN RETURN;
--      ELSE RAISE;
--      END IF;
--    ELSE
--      RAISE;
--    END IF;
END;
/




--EXEC DBMS_AQADM.drop_queue (queue_name => '&QUEUE_NAME.');
-- Drop the queue.

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :='';
   DBMS_AQADM.drop_queue (queue_name => '&QUEUE_NAME.');
EXCEPTION
  WHEN OTHERS THEN
NULL;
--    IF SQLCODE = -24010 THEN
--      SQLSTR := 'SELECT COUNT(*) from user_queues where name = ''&QUEUE_NAME.'' ';
--      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
--      IF TEMP_COUNT = 0 THEN RETURN;
--      ELSE RAISE;
--      END IF;
--    ELSE
--      RAISE;
--    END IF;
END;
/



-- Drop the queue table.
--EXEC DBMS_AQADM.drop_queue_table(queue_table => '&QUEUE_TABLE_NAME.');


DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR := '';
   DBMS_AQADM.drop_queue_table (
      queue_table => '&QUEUE_TABLE_NAME.'
      , force => TRUE
      );
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -24002 THEN
      SQLSTR := 'SELECT COUNT(*) from user_queues where queue_table = ''&QUEUE_NAME.'' ';
      EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
      IF TEMP_COUNT = 0 THEN RETURN;
      ELSE RAISE;
      END IF;
    ELSE
      RAISE;
    END IF;
END;
/



--Next, create the queue table (EVENT_QUEUE_TAB) using the payload object, define the queue (EVENT_QUEUE) and start it.

 -- Create a queue table to hold the event queue.
begin
 DBMS_AQADM.create_queue_table(
    queue_table        => '&QUEUE_TABLE_NAME.',
    queue_payload_type => 'UNPLANNED_PUBLISH_T',
    multiple_consumers => false,
    comment            => 'Queue Table Publishing Unplanned Messages');
END;
/



begin
-- Create the event queue.
  DBMS_AQADM.create_queue (
    queue_name  => '&QUEUE_NAME.',
    queue_table => '&QUEUE_TABLE_NAME.',
    comment     => 'Queue for Publishing Unplanned Messages'
    );

  -- Start the event queue.
  DBMS_AQADM.start_queue (queue_name => '&QUEUE_NAME.');
END;
/


select msg_state,ENQ_TIME, enq_user_id, user_data, deq_time, deq_user_id from AQ$&QUEUE_TABLE_NAME. ;


