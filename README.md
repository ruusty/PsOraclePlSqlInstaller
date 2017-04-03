
# CR00000 __ProjectName__

<pre style="font-size: .75em;">
Project:        OMS
Product:        CR00000-__ProjectName__-Ora.build
Version:
Date:           YYYY-MM-DD
Description:    CR00000-__ProjectName__ Oracle into SDLC OMS database.

CHED Services

</pre>

<a name="TOC"></a>
# Table of Contents

- [Description](#description)
- [References](#references)
- [Notes](#notes)

<a name="Description"></a>
## Description [&uarr;](#TOC) ##

Blah Blah



<a name="references"></a>
## References [&uarr;](#TOC) ##

Filename                                              | Database | schema    | credential file      |
:----------------                                     |:---      |:---       |:---                  |:---
130_pkg.CHED_ORDER_UTILSs-pon.oms.sql                 | pon      | oms       | oms@pond.credential  | -L oms/oms_pwd@[pon]             run.sql 130_pkg.CHED_ORDER_UTILSs-pon.oms.sql 130_pkg.CHED_ORDER_UTILSs-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log
002_clean_up-pon.oms_local.sql                        | pon      | oms_local | oms_local@local[pon] + ".credential"                      | -L oms_local/oms_local_pwd@[pon] run.sql 002_clean_up-pon.oms_local.sql        002_clean_up-pon.oms_local.sql.YYYY-MM-ddTHH-mm-ss.log
010_perms-pon.oms.sql                                 | pon      | oms       |                      |
012_types-onc.oproc.sql                               | onc      | oproc     |                      |
110_table.mod.PO_CUSTOMER_NOTIFICATION_LOG-pon.oms.sql| pon      | oms       |                      |
120_table.mod.rgh-pon.username.sql                    | pon      | $env:username  |                      |


~~~
$sqlfiles =
@{
                filename=""
                $details=@{
                    name=""
                    database=""
                    schema=""
                    password""
                    logfile=""
                    credentialFile=".credential"
                }
                
}
~~~



<a name="notes"></a>
## Notes [&uarr;](#TOC) ##

~~~
#SDLC name is used to locate this file
#No secrets here
#This is evaluated line by line
#Example $cfg_sqlSpec if the need to install a subset of sql files
#$cfg_sqlSpec=@("112_*.sql","113_*.sql","113_*.sql""5?_*.sql","6?_*.sql")
#Map the database identifier to SDLC database tnsname entry
$cfg_local=@{}

$cfg_local["pon"]="POND.world"    #OMS database
$cfg_local["onc"]="ONCD.world"    #SMS_PUSH database
~~~
