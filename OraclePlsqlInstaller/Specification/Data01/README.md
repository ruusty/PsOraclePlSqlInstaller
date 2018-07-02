# Data01 #


- Create these files using version from Data.

~~~
copy-item ..\..\data\install.bat .
copy-item ..\..\data\build.psake.ps1 .
get-content -path "..\..\data\sqlplus.psake.ps1" | %{ $_.replace("Import-Module OraclePlsqlInstaller", 'Import-Module -Name $(Join-Path $PSScriptRoot "..\..\OraclePlsqlInstaller.psm1" ) -force' )} | set-content sqlplus.psake.ps1

~~~