
DECLARE
  compile_invalid boolean := FALSE;
BEGIN
   DBMS_UTILITY.COMPILE_SCHEMA( 'OMS', compile_invalid );
END;
/

COLUMN object_name FORMAT A30
SELECT 
       object_type,
       object_name,
       status,
       subobject_name,
       created
FROM   user_objects
WHERE  status = 'INVALID'
and object_type <> 'SYNONYM'
ORDER BY  object_type, object_name;


