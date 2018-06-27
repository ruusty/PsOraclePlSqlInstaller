/*

Alter the CHED_PATCH_INFO table with a description column


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


define tabname=CHED_PATCH_INFO
define tabname

--============================================================={
define colname=DESCRIPTION
define colname

DECLARE
  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(4000);
BEGIN
  SQLSTR :=
'
ALTER TABLE  &l_owner..&tabname. ADD (
 &colname.      varchar2(80)
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


COMMENT ON COLUMN  &l_owner..&tabname..&colname. IS 'Reference to source of change';

describe &l_owner..&tabname.



