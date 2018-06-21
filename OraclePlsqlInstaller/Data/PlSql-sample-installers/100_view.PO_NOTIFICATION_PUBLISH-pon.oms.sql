define l_owner=OMS

variable own varchar2(40)
execute select '&l_owner.' into :own from dual;
show user

SELECT * FROM global_name;

alter session Set NLS_DATE_FORMAT='DD-MON-RRRR HH24:MI:SS';
alter session set current_schema = &l_owner;

whenever sqlerror exit failure rollback


DECLARE
  l_names sys.TXNAME_ARRAY ;

  CURSOR l_names_cur IS SELECT * FROM TABLE(l_names);

  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
l_names := sys.txname_array(
 'PO_NOTIFICATION_PUBLISH'
);

FOR i IN 1 .. l_names.count LOOP
   dbms_output.put_line('i=(' || i || ')=' || l_names(i));

   BEGIN
     SQLSTR :='DROP  VIEW ' || l_names(i);
     dbms_output.put_line(SQLSTR);
     EXECUTE IMMEDIATE SQLSTR;
   EXCEPTION
     WHEN OTHERS THEN
       IF SQLCODE = -00942 THEN
         SQLSTR := 'SELECT COUNT(*) from user_views where view_name = ''' || l_names(i) || ''' ';
         EXECUTE IMMEDIATE SQLSTR INTO TEMP_COUNT;
         IF TEMP_COUNT = 0 THEN NULL;
         ELSE RAISE;
         END IF;
       ELSE
         RAISE;
       END IF;
   END;
END LOOP;
END;
/


