# __ProjectName__ <!-- omit in toc --> #

~~~text
Project:        GIS-OMS
Product:        __ProjectName__-Ora
Version:        4.3.0.0
Date:           2018-11-08
Description:    __ProjectName__ Oracle into SDLC OMS database.

CHED Services
~~~

<a name="TOC"></a>

- [Description](#description)
- [Installation](#installation)

## Description ##

Installs *Pl/Sql* code into Oracle SDLC databases in a repeatable and configurable manner.

The Oracle database and schema are encoded in the pl/sql filename.

[&uarr;](#TOC)

## Installation ##

- Open a *Powershell Console*

- Execute
  
~~~powershell
.\install.ps1 -sdlc $sdlc
~~~

Where `$sdlc` == `['DEV'|'TEST'|'UAT'|'PROD']`
