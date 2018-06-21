
# Deliverable Name

~~~
Project:        GIS/OMS
Product:        DeliverableName-Ora
Version:        4.3.0.0
Date:           2018-06-21
Description:    NAME-ORA Oracle into SDLC OMS database.

CHED Services

~~~

<a name="TOC"></a>
# Table of Contents

- [Description](#description)
- [Installation](#installation)
- [References](#references)
- [Notes](#notes)


<a name="description"></a>
## Description [&uarr;](#TOC) ##

Does what ?



Installs *Pl/Sql* code into Oracle SDLC databases in a repeatable and configurable manner.

<a name="installation"></a>
## Installation [&uarr;](#TOC) ##

SDLC == `['DEV'|'TEST'|'UAT'|'PROD']`



### Step 0 (Entry Criteria) ###

The following Chocolatey packages.

~~~
cinst psake
cinst PSOraclePlSqlInstaller
~~~




### Step 1 ###

**Entry Criteria**

- Open a Windows Console at the deliverables **Win+R**
 
~~~
cmd.exe  /k cd /d  "G:\MKT\DEPT\IT Spatial\OMS GIS\Change Requests 2018\.."

~~~

- See what the install does. Will prompt for and test credentials.

~~~
install SDLC whatif
~~~


- Install the Oracle objects into the OMS database.

~~~
install SDLC 
~~~



**Exit Criteria**

`Build Succeeded!` at the end of the output.


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


`sqlplus.psake.ps1` *psake* file that orchestrates the pl/sql deployment. 


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