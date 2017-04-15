/*

Alter the CHED_PATCH_INFO table with a description column


*/

define l_owner=OMS
variable own varchar2(40)
execute select '&l_owner.' into :own from dual;

show user


alter session set current_schema = &l_owner;
whenever sqlerror exit failure rollback

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



