@rem Build wrapper
@cd /d %~dp0
call psake build.psake.ps1 -properties "@{VerbosePreference='SilentlyContinue';DebugPreference='SilentlyContinue'}" %*
@timeout /t 10


