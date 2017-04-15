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


