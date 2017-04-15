
  CREATE OR REPLACE PACKAGE "OMS"."CHED_UTILS_CFG"
   IS
/*
     $Id: ched_utils_cfg.pks 1404 2010-06-28 01:31:32Z rholliday $
 $Author: rholliday $
   $Date: 2010-06-28 11:31:32 +1000 (Mon, 28 Jun 2010) $
$HeadURL: https://corpvmcoderep01.corp.chedha.net/svn/gisoms/Projects/src/OMS/src/OMS/sql_packages/ched_utils_cfg.pks $
    $Rev: 1404 $
Debug and tracing statements used by ched_utils package are control from these public constants
*/
   debug_active CONSTANT BOOLEAN := FALSE;   /* TRUE for development and testing, FALSE for Production */
   trace_level  CONSTANT PLS_INTEGER := 10;
END ched_utils_cfg;

/


