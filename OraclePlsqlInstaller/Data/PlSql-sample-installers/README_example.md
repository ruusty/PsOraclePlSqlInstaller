
# PR-785000-DESCRIPTIVENAME

<pre style="font-size: .75em;">
Project:        
Product:        PR-000000-DESCRIPTIVENAME-Ora
Version:        4.3.0.0
Date:           2017-05-15
Description:    PR-000000-PON-ORA Oracle into SDLC OMS database.

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

Fixes the following :-

http://corpvmvsmp01/vsm9p/Core.aspx?LITE&BTN_CALLNO000000=TRUE


Enhances

http://corpvmvsmp01/vsm9p/Core.aspx?LITE&BTN_CALLNO000000=TRUE


Installs *Pl/Sql* code into Oracle SDLC databases in a repeatable and configurable manner.

<a name="installation"></a>
## Installation [&uarr;](#TOC) ##

Where SDLC == `['DEV'|'TEST'|'UAT'|'PROD']`



### Step 0 ###

Blah-Blah

### Step 1 ###

**Entry Criteria**

- Open a Windows Console at the deliverables.
 
~~~
cmd.exe  /k cd /d  "G:\MKT\DEPT\IT Spatial\OMS GIS\Change Requests 2017\PR-000000-DESCRIPTIVENAME\Deploy\PROD\PR-000000-PON-ORA.4.3.mmmm.nnnn"

~~~

- Install the Oracle objects into the OMS database.

~~~
install SDLC
~~~


### Step 2 ###



**Entry Criteria**

- Successful Step 1

Blah-Blah Description of what we are doing.



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
- Build file `build.psake.ps1` to create a zip file containing artifacts to be deployed to database
- Error handling
- Sample implementations

#### Implementation ####


`sql.default.ps1` *psake* file that orchestrates the pl/sql deployment. 

`OraclePlsqlInstaller` folder contains a PowerShell module used by the *psake* file `sql.default.ps1`

`PlSql-sample-installers` folder contains sample *pl/sql* code to install objects of different types into an Oracle database.

The aim of these installers is to allow repeatable application of the code to a database.



<a name="notes"></a>
## Notes [&uarr;](#TOC) ##


Collection of useful PowerShell cmdlets.

~~~
import-module OraclePlsqlInstaller -verbose
get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys
~~~

~~~
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}
~~~



## Working Notes ##

~~~
sqlplus.exe -L "oms/dev!43oms12@POND.world" @"run.sql" "050_table.create.PO_NOTIFICATION_PROJECT_LOG-pon.oms.sql" "050_table.create.PO_NOTIFICATION_PROJECT_LOG-pon.oms.sql.2017-06-20T09-42-54.log"

~~~