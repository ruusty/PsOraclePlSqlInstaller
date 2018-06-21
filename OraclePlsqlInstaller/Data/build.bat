@rem Build a release
@setlocal
cd /d %~dp0
call psake build.psake.ps1 -properties "@{verbose=$False;VerbosePreference='SilentlyContinue';DebugPreference='SilentlyContinue'}" build
@pause
endlocal

