# Set path that will not fail, 2 levels up from  LOCALAPPDATA
#e.g. LOCALAPPDATA=C:\Users\Russell\AppData\Local
# Should be a local disk
$poshModFolder = ".PowershellModules"
$installRootDirPath = $((Split-Path -Path $env:LOCALAPPDATA) | Split-Path) | Join-Path -child $poshModFolder

$moduleName = "OraclePlSqlInstaller" #Top filepath in zip file
$moduleDirPath = Join-Path -Path $installRootDirPath -ChildPath $moduleName
$ZipName = "PS$moduleName.zip"

$config_vars += @(
    'installRootDirPath'
    , 'moduleName'
    , 'moduleDirPath'
    , 'ZipName'
)

$config_vars | Get-Variable | Sort-Object -unique -property "Name" | Select-Object Name, value | Format-Table | Out-Host