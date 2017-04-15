
# CR00000-__ProjectName__

<pre style="font-size: .75em;">
Project:        
Product:        CR00000-__ProjectName__-Ora.build
Version:
Date:           YYYY-MM-DD
Description:    CR00000-__ProjectName__ Oracle into SDLC OMS database.

CHED Services

</pre>

<a name="TOC"></a>
# Table of Contents

- [Description](#description)
- [Installation](#installation)
- [References](#references)
- [Notes](#notes)


<a name="description"></a>
## Description [&uarr;](#TOC) ##

Delivers xyz functionality 


<a name="installation"></a>
## Installation [&uarr;](#TOC) ##

~~~
install SDLC
~~~

Where SDLC == `['DEV'|'TEST'|'UAT'|'PROD']`

<a name="references"></a>
## References [&uarr;](#TOC) ##

The Oracle code is deployed to the database in a repeatable and configurable manner. 

This enables the following :-
- Same code is applied to all SDLC Oracle databases in a consistent, trackable, and repeatable manner.
- The *pl/sql* code can be applied to the database multiple times with same result (idimpotent)
- Logging
- Error handling. If there is an error deployment stops/fails.
- Versioning of code deployment.

#### Features ####

- Oracle schema passwords are saved in encrypted `*.credential` files
- Date version log files
- Installation as simple as `install SDLC`
- Build filed to create a zip file containing artifacts to be deployed to database
- Error handling
- Sample implementations

#### Implementation ####


`sql.default.ps1` *psake* file that orchestrates the pl/sql deployment. 

`OraclePlsqlInstaller` folder contains a PowerShell module used by the *psake* file `sql.default.ps1`

`PlSql-sample-installers` folder contains sample *pl/sql* code to install objects of different types into an Oracle database.

The aim of these installers is to allow repeatable application of the code to a database.



#### Conventions ####

The pl/sql files that apply the changes to the database must adhere to a naming convention.

~~~
("[0-9_][0-9_][0-9_]_*-*.sql","[0-9_][0-9_][a-z]_*-*.sql")
~~~

**Example**
~~~
____entry_criteria-onc.username.sql
____entry_criteria-pon.oms.sql
____knownstate-onc.oproc.sql
021a_table_status_data-onc.oproc.sql
021c_views-onc.oproc.sql
022_table_UnplannedCust-onc.oproc.sql
~~~

The *pl/sql* files are applied to the database in the order displayed Windows Explorer.

The suffix after the last `-` E.G `pon.oms` determines the database and schema to execute the file with `sqlplus.exe`.

parameter   | Description     |Example
:---------- |:------          |:-----
pon         | Database        |PONP.WORLD,PONU.WORLD ....
onc         | Database        |oncd.world,oncp.world ....
oproc       | Database Schema | user account to execute the file with
oms         | Database Schema | user account to execute the file with

To install into a Development database(s)

~~~
install DEV
~~~

Targets are discoverable using 

~~~
install help
~~~


<a name="notes"></a>
## Notes [&uarr;](#TOC) ##

Targeting Production.

Pl/sql Filename                           | Database | schema         | credential file                  | Command line
:----------------                         |:---      |:---            |:---                              |:---
130_pkg.CHED_ORDER_UTILS-pon.oms.sql      | pon      | oms            | oms@ponp.world.credential        |sqlplus.exe -L "oms/oms_pwd@ponp.world"             @"run.sql" "130_pkg.CHED_ORDER_UTILS-pon.oms.sql"         "130_pkg.CHED_ORDER_UTILSs-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log"
002_clean_up-pon.oms_local.sql            | pon      | oms_local      | oms_local@ponp.world.credential  |sqlplus.exe -L "oms_local/oms_local_pwd@ponp.world" @"run.sql" "002_clean_up-pon.oms_local.sql"               "002_clean_up-pon.oms_local.sql.YYYY-MM-ddTHH-mm-ss.log"
010_perms-pon.oms.sql                     | pon      | oms            | oms@ponp.world.credential        |sqlplus.exe -L "oms/oms_pwd@ponp.world"             @"run.sql" "010_perms-pon.oms.sql"                        "010_perms-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log"
012_types-onc.oproc.sql                   | onc      | oproc          | oproc@ondp.world.credential      |sqlplus.exe -L "oproc/oproc_pwd@oncp.world"         @"run.sql" "012_types-onc.oproc.sql"                      "012_types-onc.oproc.sql.YYYY-MM-ddTHH-mm-ss.log"
110_table.mod.PO_CUSTOMER_LOG-pon.oms.sql | pon      | oms            | oproc@ondp.world.credential      |sqlplus.exe -L "oms/oms_pwd@ponp.world"             @"run.sql" "110_table.mod.PO_CUSTOMER_LOG-pon.oms.sql"    "110_table.mod.PO_CUSTOMER_LOG-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log"
120_table.mod.rgh-pon.username.sql        | pon      | $env:username  | %username%@ponp.world.credential |sqlplus.exe -L "oms/oms_pwd@ponp.world"             @"run.sql" "120_table.mod.rgh-pon.username.sql"           "120_table.mod.rgh-pon.username.sql.YYYY-MM-ddTHH-mm-ss.log"


**Regular Expressions**

value                                 | wild cards / regular expression                             | Description
:---                                  |:---                                                         |:----
`oms@ponp.world.credential `          |     todo                                                    |
`"120_table.mod.rgh-pon.username.sql"`|`("[0-9_][0-9_][0-9_]_*-*.sql", "[0-9_][0-9_][a-z]_*-*.sql")`|
