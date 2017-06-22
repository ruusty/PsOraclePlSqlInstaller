@echo off
@rem ============================================================================
@rem        Date : 2017-06-22
@rem
@rem    Function : Pl/Sql installer
@rem
@rem  Example:
@rem   Install into SDLC
@rem
@rem ===========================================================================
setlocal ENABLEDELAYEDEXPANSION
@cls
@echo off
@set buildfile=sqlplus.psake.ps1
@echo.MSG00^>Running:%~nx0
for %%i in (
""
"-help"
"-h"
"/h"
"-?"
"help"
) do (
if /I "%%~i" == "%~1"   goto batch_help "%1"
)

for %%i in ("PROD" "UAT" "TEST" "DEV") do (
if /i "%%~i"  == "%~1"  set SDLC=%%~i
)
shift /1
@echo.SDLC=%SDLC%

if  not defined sdlc goto batch_help
if "%sdlc%" == "" goto batch_help

cd /d %~dp0

@cd
hostname
whoami
@ver>nul
@rem You can override a property in your build script using the "properties" parameter of the Invoke-psake function.
@rem To summarize the differences between passing parameters and properties to the Invoke-psake function:
@rem
@rem     Parameters and "properties" can both be passed to the Invoke-psake function simultaneously
@rem     Parameters are set before any "properties" blocks are run
@rem     Properties are set after all "properties" blocks have run
@rem
@echo on
@rem call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql');verbose=$false;whatif=$true;}" -parameters "@{sdlc='%sdlc%'}" %1
@rem call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-9_]_*-*.sql');verbose=$true;whatif=$false;}" -parameters "@{sdlc='%sdlc%'}" %1
call psake "%buildfile%" -properties "@{cfg_sqlSpec=@('[0-9_][0-9_][0-8_]_*-*.sql');verbose=$false}" -parameters "@{sdlc='%sdlc%'}" %1

@echo.MSG99^>%~nx0:ERRORLEVEL=%ERRORLEVEL%
@echo on
exit /b %ERRORLEVEL%

:batch_help
@echo.%~n0 ^<SDLC^>
@echo.Example
@echo.%~n0 [PROD^|UAT^|TEST^|DEV] "tasks1,task2"
@echo.
@echo.Tasks
@psake -buildfile "%buildfile%" -docs
@exit /b 1
@goto :EOF


