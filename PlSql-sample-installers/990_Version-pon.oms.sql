show user

whenever sqlerror exit failure rollback

variable versionnum NUMBER
variable desc_str VARCHAR2(80)

-->Get Patch number from G:\MKT\DEPT\IT Spatial\OMS GIS\Support 'How To' Instruction\CHED OMS\00_Version_Description\Configuration\!OMS Patch Index.xls
execute SELECT 7598 INTO :versionnum FROM dual;
---------------^

execute SELECT 'CR33194-PON for connected cust with valid SP. @ProductVersion@' INTO :desc_str FROM dual;

print versionnum
print desc_str

alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss';

MERGE INTO OMS.CHED_PATCH_INFO A USING
 (SELECT
  SYSDATE                                 as date_applied,
  :versionnum                             as patch_number,
  SYS_CONTEXT ('USERENV', 'TERMINAL')     as machine,
  SYS_CONTEXT ('USERENV', 'SESSION_USER') as oracle_user,
  SYS_CONTEXT ('USERENV', 'OS_USER')      as os_user,
  :desc_str                               as DESCRIPTION
  FROM DUAL) B
ON (A.PATCH_NUMBER = B.PATCH_NUMBER)
WHEN NOT MATCHED THEN
INSERT (
    DATE_APPLIED,  PATCH_NUMBER,    MACHINE,   ORACLE_USER,   OS_USER,   DESCRIPTION)
VALUES (
  B.DATE_APPLIED, B.PATCH_NUMBER, B.MACHINE, B.ORACLE_USER, B.OS_USER, B.DESCRIPTION)
WHEN MATCHED THEN
UPDATE SET
  A.DATE_APPLIED = B.DATE_APPLIED,
  A.MACHINE = B.MACHINE,
  A.ORACLE_USER = B.ORACLE_USER,
  A.OS_USER = B.OS_USER,
  A.DESCRIPTION = B.DESCRIPTION
/



select * from oms.CHED_PATCH_INFO a  where a.patch_number = :versionnum;




