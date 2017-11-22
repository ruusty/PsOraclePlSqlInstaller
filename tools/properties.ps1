# Set path that will not fail, 2 levels up from  LOCALAPPDATA
#e.g. LOCALAPPDATA=C:\Users\Russell\AppData\Local
# Should be a local disk
$poshModFolder = ".PowershellModules"
$installRootDirPath = $((Split-Path -Path $env:LOCALAPPDATA) | Split-Path) | Join-Path -child $poshModFolder

# May fail because infecto disables network drive letters when in Elevated Privledge
# Causes join-path to fail. Join-path does not fail when Drive is non-existant
try
{
  $installRootDirPath = $(join-path -path $(join-path -path $env:HOMEDRIVE -child $env:HOMEPATH) -child $poshModFolder)
}
catch
{
  Write-Host $_
}

$moduleName="OraclePlSqlInstaller" #Top filepath in zip file

$ZipName ="PSOraclePlSqlInstaller.zip"

