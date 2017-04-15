define

show user

SELECT * FROM global_name;

whenever sqlerror exit failure rollback
SELECT * FROM user_role_privs WHERE granted_role = 'DBA';

DECLARE
   dba_priv_found PLS_INTEGER := 0;
BEGIN

SELECT count(*) num_priv INTO dba_priv_found FROM user_role_privs WHERE granted_role = 'DBA';

/*
if dba_priv_found = 0  then
   RAISE_application_error(-20010, 'FATAL> ' || USER || ' does not have DBA privs. Must have dba privs to run this script.' );
end if;
*/

END;
/


