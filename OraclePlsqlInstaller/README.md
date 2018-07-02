# OraclePlsqlInstaller #


~~~
Project:        
Product:        OraclePlsqlInstaller
Version:        4.4
Date:           2018-07-03
Description:    Automates installing Oracle Pl/Sql code into an Oracle database

CHED Services
~~~


<a name="TOC"></a>
# Table of Contents

- [Description](#description)
- [Usage](#usage)
- [Windows Credential Manager](#windows-credential-manager)
    - [Save-OracleCredentials](#save-oraclecredentials)
    - [Remove-OracleCredentials](#remove-oraclecredentials)
    - [Show-OracleCredentials](#show-oraclecredentials)
- [Filename](#filename)
- [Notes](#notes)



<a name="description"></a>
## Description [&uarr;](#TOC) ##

The PowerShell Module *OraclePlsqlInstaller* automates installing **Oracle Pl/Sql** code into a Oracle database in a repeatable
and automated install.

The Oracle credentials are stored in the [Windows Credential Manager](#windows-credential-manager).

The sub-folder Data under the OraclePlsqlInstaller installed location contains examples a
and boilerplate code.

~~~
get-module -listavailable oraclePlsqlInstaller
~~~

- Load the module
~~~
import-module OraclePlsqlInstaller -verbose
get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys
~~~

- Get cmdlet help
~~~
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}
~~~

~~~
get-help about_OraclePlsqlInstaller
~~~

<a name="usage"></a>
## Usage [&uarr;](#TOC) ##

Typically the *OraclePlsqlInstaller* module is used under the orchestration of `sqlplus.psake.ps1`.

The top level command is *Get-SqlPlusCommands* to return a hash table of `sqlplus.exe` commands 
based on the [Filename](#filename) convention.

~~~
 $initArgs = @{
    directory =  $PWD
    sqlSpec = @('[0-9_][0-9_][0-9_]_*-*.sql', '[0-9_][0-9_][a-z]_*-*.sql')
    logFileSuffix = $([System.DateTime]::Now).ToString("yyyy-MM-ddTHH-mm-ss");
    netServiceNames = OraclePlsqlInstaller\Set-SdlcConnections "dev";
    verbose = $true;
  }
  $script:sqlCommands = Get-SqlPlusCommands @initArgs
  $script:sqlCommands | Out-String | write-verbose
~~~

These are then executed by **psake** task *Invoke-Sqlplus*.

See [sqlplus.psake.ps1](file:./../sqlplus.psake.ps1)


- Import module and show commands
~~~
import-module OraclePlsqlInstaller
get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}

~~~


<a name="windows-credential-manager"></a>
## Windows Credential Manager [&uarr;](#TOC) ##


The **Windows Credential Manager** securely stores the Oracle Schema Passwords.

The Powershell Module **BetterCredentials**  stores and retrieves the passwords.

The Save-OracleCredentials, Remove-OracleCredential, Show-OracleCredentials
cmdlets are used to manage the import of passwords from
`G:\MKT\DEPT\IT Spatial\OMS GIS\Support 'How To' Instruction\OMS-Oracle-Config\password-check\gis-oms-Oracle.xml`
to the **Windows Credential Manager**.

~~~
Save-OracleCredentials -sdlc dev -path "G:\MKT\DEPT\IT Spatial\OMS GIS\Support 'How To' Instruction\OMS-Oracle-Config\password-check\gis-oms-Oracle.xml"
~~~

`Get-SqlPlusCommands` retrieves the passwords from the **Windows Credential Manager**
and returns the `SqlPlus.exe` command line to run the pl/sql file including password.

Launch the Credential Manager
**Win+R**
~~~
c:\windows\system32\control.exe /name Microsoft.CredentialManager
~~~


<a name="save-oracleaccounts"></a>
### Save-OracleCredentials [&uarr;](#TOC) ###

Saves the Oracle accounts username and password from the XML to 
`Control Panel\All Control Panel Items\Credential Manager` the **Windows Vault**.


The passwords can be access by the using the PowerShell Module **BetterCredentials**.

**Example**
~~~
Save-OracleCredentials -verbose -sdlc dev 
~~~

- Import Passwords from XML file.
~~~
Save-OracleCredentials -sdlc dev -path "G:\MKT\DEPT\IT Spatial\OMS GIS\Support 'How To' Instruction\OMS-Oracle-Config\password-check\gis-oms-Oracle.xml"
~~~


- Show the imported passwords from the **Windows Vault** using OraclePlsqlInstaller.
~~~
Show-OracleCredentials -verbose -sdlc dev 
~~~


- Show the imported password from the **Windows Vault** using BetterCredentials.

~~~
$UserName='ched_framework@oncd.world'
$Target = "MicrosoftPowerShell:user=$Username"
$cred=BetterCredentials\Get-Credential -username $Target
$cred.UserName
$cred.GetNetworkCredential().password
$cred.GetNetworkCredential().Username
~~~




<a name="remove-oracleaccounts"></a>
### Remove-OracleCredentials [&uarr;](#TOC) ###

Removes the Oracle Credentials from the **Windows Vault**.

~~~
Remove-OracleCredentials -sdlc dev -verbose
~~~


<a name="show-oracleaccounts"></a>
### Show-OracleCredentials [&uarr;](#TOC) ###

Show the Oracle Credentials from the **Windows Vault**.

~~~
Show-OracleCredentials -sdlc dev -verbose
~~~

<a name="filename"></a>
## Filename [&uarr;](#TOC) ##

The filename convention describes how to execute the file.

~~~
<ExecSequence>_<Description>-<DatabaseIdentifier>.<OraUser>.sql
~~~

`010_views-pon.oms_op.sql` Converts  to
`oms_op/oraPassword@pond.world @run.sql 010_views-pon.oms_op.sql 010_views-pon.oms_op.sql.log`



**NOTES**
~~~
[PSCustomObject]@{
  PSTypeName          Hash Table type = 'PSOracle.SqlPlusCmd'
  FileName            Pl/sql file name of the format 010_views-pon.oms_op.sql I.E. 010_views-<DatabaseIdentifier>.<OraUser>.sql
  OraUser             Oracle Username (SCHEMA). Translates username to actual value of $env:username
  Path                Absolute Path
  DatabaseIdentifier  The database type/model [PON,CNC,ONC]
  TnsName             Net Service Name E.G. pond.world
  LogFileName         Log file
  OraFQUserName       Oracle Fully Qualified User Name I.E. oms@pond.world rholliday@pond.world
  OraPassword
  IsInOraWallet       Is the password in the Oracle Wallet. Only used for username
  sqlplusArgs         Array of arguments to sqlplus.exe
  OraConnection       Oracle connect string to the database E.G. /@pond.world , oms/password@pond.world
~~~

**EXAMPLE**
~~~
FileName           : 140_pkg.PLANNED_OUTAGE-pon.oms.sql
OraUser            : oms
Path               : E:\Projects-Active\PSOraclePlSqlInstaller\OraclePlsqlInstaller\Specification\Data\140_pkg.PLANNED_OUTAGE-pon.oms.sql
DatabaseIdentifier : pon
TnsName            : POND.world
LogFileName        : 140_pkg.PLANNED_OUTAGE-pon.oms.sql.YYYY-MM-ddTHH-mm-ss.log
OraFQUserName      : oms@POND.world
OraPassword        : oms.password
IsInOraWallet      : False
sqlplusArgs        : {-L, "oms/oms.password@POND.world", @"run.sql", "140_pkg.PLANNED_OUTAGE-pon.oms.sql"...}
OraConnection      : "oms/oms.password@POND.world"
~~~

**EXAMPLE**
~~~
FileName           : ____entry_criteria-onc.username.sql
OraUser            : Russell
Path               : E:\Projects-Active\PSOraclePlSqlInstaller\OraclePlsqlInstaller\Specification\Data\____entry_criteria-onc.username.sql
DatabaseIdentifier : onc
TnsName            : ONCD.world
LogFileName        : ____entry_criteria-onc.username.sql.YYYY-MM-ddTHH-mm-ss.log
OraFQUserName      : Russell@ONCD.world
OraPassword        :
IsInOraWallet      : True
sqlplusArgs        : {-L, "/@ONCD.world", @"run.sql", "____entry_criteria-onc.username.sql"...}
OraConnection      : "/@ONCD.world"
~~~


<a name="notes"></a>
## Notes [&uarr;](#TOC) ##


- Pester test are incomplete.

- Hash table for each *.sql file

~~~
   $details = @{
            fileName = $fname
            oraUser = $oraUser
            path = $_.ProviderPath
            databaseIdentifier = $conn[0] # The database type/model 
            tnsName          = $netServiceNames[$conn[0]] # a Net Service Name
            logFileName = [System.IO.Path]::GetFileName($_) + "." + $logFileSuffix + ".log"
            credentialFileName = $(join-path $directory $($oraUser + "@" + $netServiceNames[$conn[0]] + ".credential"))
            oraPassword = ""
            sqlplusArgs = @()
~~~

Then can validate


~~~
[validatescript({
            $argKeys=@('fileName', 'oraUser', 'path','databaseIdentifier','tnsName',
            'logFileName' ,'credentialFileName','oraPassword','sqlplusArgs' )
            foreach($key in $_.keys){
                if($argKeys -notcontains $key)
                {
                    throw $("$Key is invalid, must be {0}" -f $($argKeys -join ', '))
                }
            }
            $true
        })]
        [System.Collections.Hashtable[]]$Fields,
~~~