--whenever sqlerror continue

---- When in development we want to expose the private functions for unit testing
--
--declare
--   cursor m_settings_cur is
--   select * from (
--   select name,value from config
--   )
--   pivot (max(value) for name in (
--'SDLC_ENVIRONMENT'           as SDLC_ENVIRONMENT
--   ));
--
--   m_settings m_settings_cur%rowtype;
--begin
--   for r in m_settings_cur loop      m_settings := r;   end loop;
--   dbms_output.put_line (m_settings.sdlc_environment);
--   if m_settings.sdlc_environment = 'DEV' then
--   dbms_output.put_line('Compiling DEV config: Exposing private functions and procedures');
--   execute immediate '
--   CREATE OR REPLACE PACKAGE OPROC."PACKAGE_CONFIG" AS
--/*
--OPROC global Debug and compile settings
--*/
--   UNIT_TEST    CONSTANT BOOLEAN     := TRUE;               --Used in optional compilation when doing unit test.
--                                                            --FALSE in Production,Test TRUE in Development for unit testing
--   APEX        CONSTANT BOOLEAN      := FALSE;              --Is APEX installed, ie ''select 1 from apex_application_items where rownum = 1'' into l_dummy;
--END PACKAGE_CONFIG;';
--   end if ;
--end;
--/   
--

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


