@rem Build wrapper
@cd /d %~dp0
call psake build.psake.ps1 -parameters "@{VerbosePreference='Continue';DebugPreference='Continue'}" %*


