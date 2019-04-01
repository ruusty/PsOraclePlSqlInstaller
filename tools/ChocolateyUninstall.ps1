#Uninstall exportpoints
write-host chocolateyPackageFolder  =$env:chocolateyPackageFolder
write-host chocolateyPackageName    =$env:chocolateyPackageName
write-host chocolateyPackageVersion =$env:chocolateyPackageVersion

$tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
.  $(join-path $tools "properties.ps1")
$ErrorActionPreference = 'Stop'
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

UnInstall-ChocolateyZipPackage -PackageName $env:chocolateyPackageName -ZipFileName $ZipName

Write-Verbose "Removing all version of '$moduleName' from '$moduleDirPath'."
Remove-Item -Path $moduleDirPath -Recurse -Force -ErrorAction SilentlyContinue
