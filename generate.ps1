<#
  .SYNOPSIS
    Create Oracle PlSql runner from a template

  .EXAMPLE
    		PS .\generate.ps1 ..\ched-PSExcel

  .NOTES
    Additional information about the file.
#>
[CmdletBinding()]
param
(
  [Parameter(Mandatory = $true)]
  [string]$DestPath
)
$ErrorActionPreference= 'Stop'
if (!(Test-Path $DestPath))
{
  $x = [System.DateTime]::Now
  Set-Variable -Name "IsoDateTimeStr" -Description "Time and Date Stamp string" -Value $([string]::Format('{0}-{1:d2}-{2:d2}T{3:d2}-{4:d2}-{5:d2}', $x.year, $x.month, $x.day, $x.hour, $x.minute, $x.second))
  Set-Variable -Name "IsoDateStr"     -Description "Time and Date Stamp string" -Value $([string]::Format('{0}-{1:d2}-{2:d2}', $x.year, $x.month, $x.day))
  mkdir $DestPath
  $pkgName = [System.IO.Path]::GetFileName($DestPath)

  get-content CR00000-__ProjectName__-Ora.build | % { $_.replace("__ProjectName__", $pkgName) }  |% { $_.replace("__localdate__", $IsoDateStr) }  | set-content $(Join-Path $DestPath "$pkgName.build")
  get-content README.md                               | % { $_.replace("__ProjectName__", $pkgName) }  | % { $_.replace("__localdate__", $IsoDateStr) } | set-content $(Join-Path $DestPath "README.md")

  copy-item __template__.gitignore      $(Join-Path $DestPath ".gitignore")
  copy-item default.ps1                 $(Join-Path $DestPath "default.ps1")
  copy-item DEV.config                  $(Join-Path $DestPath "DEV.config")
  copy-item get-build_list.ps1          $(Join-Path $DestPath "get-build_list.ps1")
  copy-item install.bat                 $(Join-Path $DestPath "install.bat")
  copy-item PlSql-Runner.zip            $(Join-Path $DestPath "PlSql-Runner.zip")
  copy-item run.sql                     $(Join-Path $DestPath "run.sql")
  copy-item show-OraSecret.ps1          $(Join-Path $DestPath "show-OraSecret.ps1")
}
else
{
  Write-Host "$DestPath Exists"
}

