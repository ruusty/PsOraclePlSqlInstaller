--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

alter session set current_schema = &l_owner.;


SELECT * FROM user_role_privs WHERE granted_role = 'DBA';

DECLARE
   dba_priv_found PLS_INTEGER := 0;
BEGIN

SELECT count(*) num_priv INTO dba_priv_found FROM user_role_privs WHERE granted_role = 'DBA';

if dba_priv_found = 0  then
   RAISE_application_error(-20010, 'FATAL> ' || USER || ' does not have DBA privs. Must have dba privs to run this script.' );
end if;


END;
/


