# OraclePlsqlInstaller #
<pre style="font-size: .75em;"><code>
Project:        GIS/OMS
Product:        OraclePlsqlInstaller
Version:        4.3
Date:           2017-04-03
Description:    Automates installing Oracle Pl/Sql code into an Oracle database

CHED Services
-------------------------------------------------------------------------------
</code></pre>


<a name="TOC"></a>
# Table of Contents

- [Description](#Description)

<a name="Description"></a>
## Description [^](#TOC) ##

*OraclePlsqlInstaller* automates installing Oracle Pl/Sql code into an Oracle database



~~~
import-module OraclePlsqlInstaller -verbose

get-module OraclePlsqlInstaller | select -expand ExportedCommands
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys
~~~

~~~
$(get-module OraclePlsqlInstaller).ExportedCommands.Keys |% {get-help $_}
~~~