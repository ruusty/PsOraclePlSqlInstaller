/*
Add the Unplanned dbms_scheduler jobs
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



column REPEAT_INTERVAL format a20 wrapped
column JOB_ACTION      format a20 wrapped
column COMMENTS        format a60 wrapped
column END_DATE        format a35 wrapped
column LAST_START_DATE format a35 wrapped
column START_DATE      format a35 wrapped
column NEXT_RUN_DATE   format a35 wrapped




define JOB_ACTION=UNPLANNED_PUBLISHER
define JOB_NAME=&JOB_ACTION._JOB

whenever sqlerror exit failure rollback

@ sql/scheduler_remove.sql &JOB_NAME.

begin
dbms_scheduler.create_job(
 job_name        => '&JOB_NAME.'
,job_type        => 'STORED_PROCEDURE'
,job_class       => 'DEFAULT_JOB_CLASS'
,job_action      => '&JOB_ACTION.'
,start_date      => TO_TIMESTAMP_TZ('2015/03/01 00:00:00.000000 +11:00','yyyy/mm/dd hh24:mi:ss.ff tzr')
,repeat_interval => NULL
,end_date        => NULL
,auto_drop       => false
,comments        => 'Publishes Unplanned Outage events to the USB, by dequeuing messages fromt the queue '
);
end;
/


BEGIN
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => '&JOB_NAME.'
     ,attribute => 'RESTARTABLE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => '&JOB_NAME.'
     ,attribute => 'LOGGING_LEVEL'
     ,value     => SYS.DBMS_SCHEDULER.LOGGING_OFF);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => '&JOB_NAME.'
     ,attribute => 'MAX_FAILURES');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => '&JOB_NAME.'
     ,attribute => 'MAX_RUNS');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => '&JOB_NAME.'
     ,attribute => 'STOP_ON_WINDOW_CLOSE'
     ,value     => FALSE);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => '&JOB_NAME.'
     ,attribute => 'JOB_PRIORITY'
     ,value     => 3);
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE_NULL
    ( name      => '&JOB_NAME.'
     ,attribute => 'SCHEDULE_LIMIT');
  SYS.DBMS_SCHEDULER.SET_ATTRIBUTE
    ( name      => '&JOB_NAME.'
     ,attribute => 'AUTO_DROP'
     ,value     => FALSE);
END;
/


SELECT job_name, state, next_run_date, enabled, repeat_interval, job_action, start_date, job_creator, job_type,  last_start_date,  end_date, run_count, failure_count, comments
FROM all_scheduler_jobs
WHERE owner = '&l_owner.' and job_name ='&JOB_NAME.'
/



define JOB_ACTION=UNPLANNED_PUBLISHER_MONITOR
define JOB_NAME=&JOB_ACTION._JOB
define JOB_NAME=UNPLANNED_PUBLISHER_MON_JOB
define JOB_NAME

@ sql/scheduler_remove.sql &JOB_NAME.

begin
dbms_scheduler.create_job(
 job_name   => '&JOB_NAME.'
,job_type   => 'STORED_PROCEDURE'
,job_action => '&JOB_ACTION.'
,start_date => sysdate
,auto_drop  => false
,repeat_interval =>'freq=HOURLY;BYMINUTE=0,15,30,45'
,comments   => 'Monitors the length of the queue UNPLANNED_PUBLISH and the UNPLANNED_PUBLISHER_JOB is running. Sends an email message to oms_support email distribution group.'
);
end;
/

execute dbms_scheduler.enable(name  => '&JOB_NAME.'  );

set echo off
set heading on
set pagesize 999
column NEXT_RUN_DATE    format a20 wrapped
column REPEAT_INTERVAL  format a20 wrapped
column JOB_ACTION       format a20 wrapped
column START_DATE       format a20 wrapped
column NEXT_RUN_DATE    format a20 wrapped
column COMMENTS         format a20 wrapped
column LAST_START_DATE  format a20 wrapped
column END_DATE         format a20 wrapped

SELECT job_name, state, next_run_date, enabled, repeat_interval, job_action, start_date, job_creator, job_type,  last_start_date,  end_date, run_count, failure_count, comments
FROM all_scheduler_jobs
WHERE owner = '&l_owner.' and job_name ='&JOB_NAME.'
/

prompt SUCCESS

DISCONNECT
exit

