# OraclePlsqlInstaller #
<pre style="font-size: .75em;"><code>
Project:        
Product:        OraclePlsqlInstaller
Version:        4.3
Date:           2017-04-03
Description:    Automates installing Oracle Pl/Sql code into an Oracle database

CHED Services
-------------------------------------------------------------------------------
</code></pre>


<a name="TOC"></a>
# Table of Contents

- [Description](#description)
- [Usage](#usage)
- [Examples](#examples)
- [Notes](#notes)



<a name="description"></a>
## Description [&uarr;](#TOC) ##

*OraclePlsqlInstaller* automates installing Oracle Pl/Sql code into an Oracle database



~~~
import-module OraclePlsqlInstaller -verbose

get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys
~~~

~~~
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}
~~~

<a name="usage"></a>
## Usage [&uarr;](#TOC) ##

Typically the *OraclePlsqlInstaller* module is used under the orchestration of `sqlplus.psake.ps1`.

The top level command is *Get-SqlPlusCommands* to return a hash table of `sqlplus.exe` commands.

~~~
 $initArgs = @{
    directory =  
    sqlSpec = $cfg_sqlSpec;
    logFileSuffix = $IsoDateTimeStr;
    netServiceNames = Set-SdlcConnections $sdlc.ToUpper();
    verbose = $verbose;
  }
  $script:sqlCommands = Get-SqlPlusCommands @initArgs
  $script:sqlCommands | Out-String | write-verbose
~~~

These are then executed by psake task *Invoke-Sqlplus*.

See [sqlplus.psake.ps1](file:./../sqlplus.psake.ps1)


<a name="examples"></a>
## Examples [&uarr;](#TOC) ##

~~~
import-module R:\Projects-Ruusty\PSOraclePlSqlInstaller\OraclePlsqlInstaller\OraclePlsqlInstaller.psm1
get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}

~~~

~~~
Show-OracleSecret *.credential
~~~

~~~
Start-Exe ping.exe 
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