@echo off
@rem Run all the Pester tests and zip results into date versioned zip file based on data source
@setlocal
for %%i in (
"-help"
"-h"
"/h"
"-?"
"help"
) do (
if /I "%%~i" == "%~1"   goto batch_help "%1"
)

@rem for %%i in ("PROD" "UAT" "DEV") do (
@rem if /i "%%~i"  == "%~1"  set SDLC=%%~i
@rem )
@rem shift /1
@rem @echo.SDLC=%SDLC%
@rem
@rem if "%SDLC%" == "DEV"  set l_datasource=sweg43d.world
@rem if "%SDLC%" == "UAT"  set l_datasource=sweg43u.world
@rem if "%SDLC%" == "PROD" set l_datasource=sweg43p.world
@rem
@rem @echo.l_datasource=%l_datasource%
@rem
@rem if  not defined sdlc goto batch_help
@rem if "%sdlc%" == "" goto batch_help

cd /d %~dp0
@call :SetIsoDateTime

@set xname1=%~n0
@rem @echo.xname1     %xname1%
@rem Publish-OraclePlsqlInstaller.Module.Tests.bat
@rem 12345678901234567890
@set JobName=%xname1:~8%
@set TestName=%JobName%
@echo on


@rem Settings
@rem @set TestName=Sweg-Features-view
@rem Settings end

@echo.%JobName% Testing
@echo.=========================
@set l_OutDir=%~dp0Test-Observations
@set l_OutputXmlFile=%l_OutDir%\%JobName%.xml
@set l_OutputHtmlFile=%l_OutDir%\%JobName%.html
@set l_pestertests=%TestName%.ps1
@set l_zipPath=%l_OutDir%\%JobName%-Results.%iso_datetime%.zip

@echo.l_OutDir         %l_OutDir%
@echo.l_zipPath        %l_zipPath%
@echo.l_OutputXmlFile  %l_OutputXmlFile%
@echo.l_OutputHtmlFile %l_OutputHtmlFile%
@echo.l_pestertests    %l_pestertests%


@del /Q "%l_OutDir%\*.html" >nul 2>>&1
@del /Q "%l_OutDir%\*.xml"  >nul 2>>&1

%windir%\SysWOW64\cmd.exe /c Pester.bat -OutputFile "%l_OutputXmlFile%" -OutputFormat NUnitXml  -Script @{ Path = './%l_pestertests%' ; Parameters= @{Verbose=$true;}}
@set rv=%ERRORLEVEL%
@echo.ERRORLEVEL %ERRORLEVEL%
@ReportUnit.exe "%l_OutputXmlFile%" "%l_OutputHtmlFile%"


:zipit
7z.exe a -tzip -bb3 "%l_zipPath%" "%l_OutDir%\*" -x!*.zip

@endlocal


@goto :EOF
:batch_help
@echo.Batch help message
@echo."%~n0"
@echo."%~n0"
@goto :EOF





@goto :EOF
:SetIsoDateTime
@rem http://stackoverflow.com/questions/20246889/get-date-and-time-on-same-line
@rem Get the date and time in a locale-agnostic way
@rem sets the env vars
@rem iso_date
@rem iso_time
@rem iso_datetime
@for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do @set %%x
@rem Leading zeroes for everything that could be only one digit
@set Month=0%Month%
@set Day=0%Day%
@rem Hours need special attention if one wants 12-hour time (who wants that?)
@set Hour24=%Hour%
@set Hour24=0%Hour24%
@if %Hour% GEQ 12 (@set AMPM=PM) else (@set AMPM=AM)
@set /a Hour=Hour %% 12
@if %Hour%==0 (@set Hour=12)
@set Hour=0%Hour%
@set Minute=0%Minute%
@set Second=0%Second%
@set Month=%Month:~-2%
@set Day=%Day:~-2%
@set Hour=%Hour:~-2%
@set Hour24=%Hour24:~-2%
@set Minute=%Minute:~-2%
@set Second=%Second:~-2%
@rem Now you can just create your output string
@rem echo.%Day%/%Month%/%Year% %Hour%:%Minute%:%Second% %AMPM%
@rem echo.%Year%-%Month%-%Day%T%Hour24%-%Minute%-%Second%
@set iso_date=%Year%-%Month%-%Day%
@set iso_time=%Hour24%-%Minute%-%Second%
@set iso_datetime=%iso_date%T%iso_time%
@set Month=
@set Hour24=
@set Day=
@set Hour=
@set Hour24=
@set Minute=
@set Second=
@ver >nul 2>&1
@goto :EOF

rem  end of file
