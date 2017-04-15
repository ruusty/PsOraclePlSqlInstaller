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


<a name="notes"></a>
## Notes [&uarr;](#TOC) ##

Hash table for each *.sql file




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

Now to validate


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