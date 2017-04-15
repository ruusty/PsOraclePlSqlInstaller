define

show user

SELECT * FROM global_name;

whenever sqlerror exit failure rollback


select
    owner
  , job_name
  , job_subname
  , session_id
  , slave_process_id
  , slave_os_process_id
  , running_instance
  , resource_consumer_group
  , elapsed_time
  , cpu_used
   from all_SCHEDULER_RUNNING_JOBS;


--ORA-27475: "OPROC.UNPLANNED_PUBLISHER_JOB1" must be a job
--ORA-27366: job "OPROC.UNPLANNED_PUBLISHER_JOB" is not running

-- Stop the Unplanned publisher job gracefully
begin
dbms_scheduler.stop_job(
       job_name  => 'UNPLANNED_PUBLISHER_JOB'
     , force => FALSE
    );
exception
   WHEN OTHERS THEN
      IF SQLCODE = -27475 OR SQLCODE = -27366 THEN
         NULL;
      ELSE
         RAISE;
      END IF;
end;
/

--ORA-27476: "OPROC.UNPLANNED_PUBLISHER_JOB" does not exist
begin
 dbms_scheduler.disable(name  => 'UNPLANNED_PUBLISHER_JOB'  );
exception
   WHEN OTHERS THEN
      IF SQLCODE = -27476 THEN
         NULL;
      ELSE
         RAISE;
      END IF;
end;
/


-- Stop the Unplanned publisher job gracefully
begin
dbms_scheduler.stop_job(
       job_name  => 'UNPLANNED_PUBLISHER_MON_JOB'
     , force => FALSE
    );
exception
   WHEN OTHERS THEN
      IF SQLCODE = -27475 OR SQLCODE = -27366 THEN
         NULL;
      ELSE
         RAISE;
      END IF;
end;
/


--ORA-27476: "OPROC.UNPLANNED_PUBLISHER_JOB" does not exist
begin
 dbms_scheduler.disable(name  => 'UNPLANNED_PUBLISHER_MON_JOB'  );
exception
   WHEN OTHERS THEN
      IF SQLCODE = -27476 THEN
         NULL;
      ELSE
         RAISE;
      END IF;
end;
/



select
    owner
  , job_name
  , job_subname
  , session_id
  , slave_process_id
  , slave_os_process_id
  , running_instance
  , resource_consumer_group
  , elapsed_time
  , cpu_used
   from all_SCHEDULER_RUNNING_JOBS;


SELECT job_name, state, next_run_date, enabled, repeat_interval, job_action, start_date, job_creator, job_type,  last_start_date,  end_date, run_count, failure_count, comments
FROM all_scheduler_jobs
WHERE owner = 'OPROC'
/

select * from user_synonyms where synonym_name ='PKG_OP_WEB_SERVICE_FUNCTIONS';

begin
  execute immediate 'DROP SYNONYM PKG_OP_WEB_SERVICE_FUNCTIONS';

  exception
  when others then
     if sqlcode = -01434 then
        null;
     else
        raise;
     end if;
end;
/


