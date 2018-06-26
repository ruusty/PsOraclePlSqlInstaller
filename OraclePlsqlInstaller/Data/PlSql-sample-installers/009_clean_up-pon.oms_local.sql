/*

Remove  objects 


*/
--     column             define
column USERNAME new_value l_owner noprint
variable OWN varchar2(40)
COLUMN OWN format A15 wrapped

select USERNAME from user_users;
execute select USERNAME into :OWN from user_users;
print OWN
define l_owner

EXECUTE alter session set current_schema = :OWN;


--============================================================={
-- DROP FUNCTIONS

DECLARE
l_names sys.TXNAME_ARRAY ;

CURSOR l_names_cur IS SELECT * FROM TABLE(l_names);

  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
l_names := sys.txname_array(
  'FUNCTION01'
);

FOR i IN 1 .. l_names.count LOOP
   dbms_output.put_line('i=(' || i || ')=' || l_names(i));

   BEGIN
     SQLSTR :='DROP FUNCTION ' || l_names(i) ;
     dbms_output.put_line(SQLSTR);
     EXECUTE IMMEDIATE SQLSTR;
   EXCEPTION
     WHEN OTHERS THEN
       IF SQLCODE = -04043  THEN
         SQLSTR := 'SELECT COUNT(*) from user_objects where object_name = ''' || l_names(i) || ''' ';
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



--=============================================================}





--============================================================={
-- DROP PROCEDURES

DECLARE
l_names sys.TXNAME_ARRAY ;

CURSOR l_names_cur IS SELECT * FROM TABLE(l_names);

  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
l_names := sys.txname_array(
  'PROC01'
 ,'PROC02'
);

FOR i IN 1 .. l_names.count LOOP
   dbms_output.put_line('i=(' || i || ')=' || l_names(i));

   BEGIN
     SQLSTR :='DROP PROCEDURE ' || l_names(i) ;
     dbms_output.put_line(SQLSTR);
     EXECUTE IMMEDIATE SQLSTR;
   EXCEPTION
     WHEN OTHERS THEN
       IF SQLCODE = -04043  THEN
         SQLSTR := 'SELECT COUNT(*) from user_objects where object_name = ''' || l_names(i) || ''' ';
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



--=============================================================}





--============================================================={
host title "Drop tables"

DECLARE
l_names sys.TXNAME_ARRAY ;


CURSOR l_names_cur IS SELECT * FROM TABLE(l_names);

  TEMP_COUNT NUMBER;
  SQLSTR VARCHAR2(200);
BEGIN
l_names := sys.txname_array(
 'TABLE_01'
,'TABLE_02'
);

FOR i IN 1 .. l_names.count LOOP
   dbms_output.put_line('i=(' || i || ')=' || l_names(i));

   BEGIN
     SQLSTR :='DROP  TABLE ' || l_names(i) || ' purge';
     dbms_output.put_line(SQLSTR);
     EXECUTE IMMEDIATE SQLSTR;
   EXCEPTION
     WHEN OTHERS THEN
       IF SQLCODE = -00942 THEN
         SQLSTR := 'SELECT COUNT(*) from user_tables where table_name = ''' || l_names(i) || ''' ';
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



--=============================================================}



DECLARE
  compile_invalid boolean := FALSE;
BEGIN
   DBMS_UTILITY.COMPILE_SCHEMA( :own, compile_invalid );
END;
/


-- Check no invalid objects

Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from all_objects o
where status <> 'VALID'
and object_type not in ('SYNONYM', 'INDEX')
UNION ALL
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from all_objects
where object_type = 'INDEX'
and ( object_name) in (SELECT  index_name
                             FROM   user_INDEXES
                             WHERE  status = 'UNUSABLE'
 UNION ALL
                             SELECT  index_name
                             FROM   user_IND_PARTITIONS ip
                             WHERE  status = 'UNUSABLE'
 UNION ALL
                             SELECT  index_name
                             FROM   user_IND_SUBPARTITIONS isp
                             WHERE  status = 'UNUSABLE'
                             )
order by object_name
/




declare
num_invalid_objs pls_integer;
begin
   num_invalid_objs :=0;
   select count(*) into num_invalid_objs
   from (

Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from all_objects o
where status <> 'VALID'
and object_type not in ('SYNONYM', 'INDEX')
UNION ALL
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from all_objects
where object_type = 'INDEX'
and ( object_name) in (SELECT  index_name
                             FROM   user_INDEXES
                             WHERE  status = 'UNUSABLE'
 UNION ALL
                             SELECT  index_name
                             FROM   user_IND_PARTITIONS ip
                             WHERE  status = 'UNUSABLE'
 UNION ALL
                             SELECT  index_name
                             FROM   user_IND_SUBPARTITIONS isp
                             WHERE  status = 'UNUSABLE'
                             )
order by object_name


         ) ;

if num_invalid_objs >0  then
   --RAISE_application_error(-20010, 'FATAL> ' || num_invalid_objs || ' invalid objects found in ' || :own || ' there should be none.');
   NULL;
end if;
end;
/

