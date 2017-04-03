@echo off
@rem ============================================================================
@rem
@rem     Project : GIS/OMS
@rem
@rem        Date : 2016-02-11
@rem Copyright (c) Ched Services
@rem
@rem    Function : Execute and log SQL files applied to a database
@rem
@rem  Example:
@rem   Install SDLC
@rem
@rem ===========================================================================
setlocal
@cls
@echo off
@echo.MSG00^>Running:%~nx0
for %%i in (".") do set JobName=%%~ni
if /I "%1" == ""      goto batch_help "%1"
if /I "%1" == "-help" goto batch_help "%1"
if /I "%1" == "-h"    goto batch_help "%1"
if /I "%1" == "/h"    goto batch_help "%1"
if /I "%1" == "-?"    goto batch_help "%1"
if /I "%1" == "help"  goto batch_help "%1"


if /i "%1" EQU "PROD" set sdlc_ENVIRONMENT=PROD
if /i "%1" EQU "UAT"  set sdlc_ENVIRONMENT=UAT
if /i "%1" EQU "TEST" set sdlc_ENVIRONMENT=TEST
if /i "%1" EQU "DEV"  set sdlc_ENVIRONMENT=DEV

if  not defined sdlc_ENVIRONMENT goto batch_help
if "%sdlc_ENVIRONMENT%" == "" goto batch_help

cd /d %~dp0

@cd
whoami
@ver>nul
@rem parameters overide those in .config\config.ps1
@rem properties must exist only override with parameters
@rem to turn Verbose off @{VerbosePreference=[System.Management.Automation.ActionPreference]::SilentlyContinue}
@rem parameter overide properties
@echo on
@rem call psake sql.default.ps1 -properties "@{VerbosePreference='Continue';cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql','[0-9_][0-9_][a-z]_*-*.sql')}" -parameters "@{JobName='%JobName%';sdlc_environment='%sdlc_ENVIRONMENT%';}" %~2
call psake sql.default.ps1 -properties "@{VerbosePreference='SilentlyContinue';cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql')}" -parameters "@{JobName='%JobName%';sdlc_environment='%sdlc_ENVIRONMENT%';}" %~2
@echo.MSG99^>%~nx0:ERRORLEVEL=%ERRORLEVEL%
@echo on
exit /b %ERRORLEVEL%

:batch_help
@echo.%~n0 ^<SDLC^>
@echo.Example
@echo.%~n0 [PROD^|UAT^|TEST^|DEV] tasks1,task2
@echo.
@echo.Tasks
@psake -docs
@goto :EOF



