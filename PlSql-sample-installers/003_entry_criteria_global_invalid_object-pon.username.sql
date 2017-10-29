define

show user

SELECT * FROM global_name;

whenever sqlerror exit failure rollback


Prompt Show all invalid object in the database.
select * from
(
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from sys.DBA_OBJECTS o
where status <> 'VALID'
and object_type not in ('SYNONYM', 'INDEX')
UNION ALL
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from sys.DBA_OBJECTS
where object_type = 'INDEX'
and (owner, object_name) in (SELECT owner, index_name
                             FROM   sys.DBA_INDEXES
                             WHERE  status = 'UNUSABLE'
                             UNION ALL
                             SELECT index_owner, index_name
                             FROM   sys.DBA_IND_PARTITIONS ip
                             WHERE  status = 'UNUSABLE'
                             UNION ALL
                             SELECT index_owner, index_name
                             FROM   sys.DBA_IND_SUBPARTITIONS isp
                             WHERE  status = 'UNUSABLE'
                             )
                             )
where owner not in ('PO_SIMULATION1','PO_SIMULATION2','ARCHIVER_DEV','OMS_OP')
order by object_name
/


DECLARE
   num_invalid_objs PLS_INTEGER := 0;
      CURSOR invalid_obj_cur IS
      SELECT count(*) num_invalid_objs FROM ( select * from
(
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from sys.DBA_OBJECTS o
where status <> 'VALID'
and object_type not in ('SYNONYM', 'INDEX')
UNION ALL
Select owner, object_name, object_type, LAST_DDL_TIME, object_id
from sys.DBA_OBJECTS
where object_type = 'INDEX'
and (owner, object_name) in (SELECT owner, index_name
                             FROM   sys.DBA_INDEXES
                             WHERE  status = 'UNUSABLE'
                             UNION ALL
                             SELECT index_owner, index_name
                             FROM   sys.DBA_IND_PARTITIONS ip
                             WHERE  status = 'UNUSABLE'
                             UNION ALL
                             SELECT index_owner, index_name
                             FROM   sys.DBA_IND_SUBPARTITIONS isp
                             WHERE  status = 'UNUSABLE'
                             )
                             )
where owner not in ('PO_SIMULATION1','PO_SIMULATION2','ARCHIVER_DEV','OMS_OP'))
;


BEGIN

FOR r IN invalid_obj_cur LOOP
   num_invalid_objs := r.num_invalid_objs;
END LOOP;

if num_invalid_objs > 0  then
   RAISE_application_error(-20010, 'WARNING> ' || num_invalid_objs || ' invalid object found in database.  Check invalid objects were not a side effect of this deployment');
end if;


END;
/



