<#
.SYNOPSIS

psake script to build a deliverable versioned zip file of Pl/Sql scripts.

.NOTES
The Project Name is the current directory name
Copies the deliverable to the Build Folder
Creates a versioned zip file in the Dist Folder
Copies files in the Dist Folder to Delivery

#>
Framework '4.0'
Set-StrictMode -Version 4
$me = $MyInvocation.MyCommand.Definition
filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }

FormatTaskName "`r`n[------{0}------]`r`n"

Import-Module Ruusty.ReleaseUtilities
import-module md2html

 <#
  .SYNOPSIS
    Get a setting from xml
  
  .DESCRIPTION
    A detailed description of the Get-SettingFromXML function.

#>
function Get-SettingFromXML
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 0)]
    [system.Xml.XmlDocument]$Xmldoc,
    [Parameter(Mandatory = $true,
               Position = 1)]
    [string]$xpath
  )
  write-debug $('Getting value from xpath : {0}' -f $xpath)
  try
  {
    $Xmldoc.SelectNodes($xpath).value
  }
  # Catch specific types of exceptions thrown by one of those commands
  catch [System.Exception] {
    Write-Error -Exception $_.Exception
  }
  # Catch all other exceptions thrown by one of those commands
  catch
  {
   Throw "XML error"
  }
}



properties {
  Write-Verbose "Verbose is ON"
  $IsVerbose = ($VerbosePreference -eq 'Continue')
  $script:config_vars = @()
  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
      "GlobalPropertiesName"
     ,"GlobalPropertiesPath"
     ,"VerbosePreference"
     ,"DebugPreference"
  )
  $whatif = $false;
  $now = [System.DateTime]::Now
  $Branch = & { git symbolic-ref --short HEAD }
  $isMaster = if ($Branch -eq 'master') {$true} else {$false}
  write-debug($("CurrentLocation={0}" -f $executionContext.SessionState.Path.CurrentLocation))
  $GlobalPropertiesName=$("GisOms.Chocolatey.properties.{0}.xml" -f $env:COMPUTERNAME)
  $GlobalPropertiesPath = Ruusty.ReleaseUtilities\Find-FileUp "GisOms.Chocolatey.properties.${env:COMPUTERNAME}.xml" 
  Write-Host $('$GlobalPropertiesPath:{0}' -f $GlobalPropertiesPath)
  $GlobalPropertiesXML = New-Object XML
  $GlobalPropertiesXML.Load($GlobalPropertiesPath)
  
  $script:config_vars += @(
  "whatif"
  ,"now"
  ,"Branch"
  ,"isMaster"
    )
  
  $GitExe = Get-SettingFromXML -xmldoc $GlobalPropertiesXML -xpath "/project/property[@name='git.exe']"
  $7zipExe = Get-SettingFromXML -xmldoc $GlobalPropertiesXML -xpath "/project/property[@name='tools.7zip']"
  $ProjMajorMinor = Get-SettingFromXML -xmldoc $GlobalPropertiesXML -xpath "/project/property[@name='GisOms.release.MajorMinor']"
  $CoreDeliveryDirectory= Get-SettingFromXML -xmldoc $GlobalPropertiesXML -xpath "/project/property[@name='core.delivery.dir']"
  $CoreReleaseStartDate = Get-SettingFromXML -xmldoc $GlobalPropertiesXML -xpath "/project/property[@name='GisOms.release.StartDate']"

  $script:config_vars += @(
  ,"GitExe"
  ,"7zipExe"
  ,"ProjMajorMinor"
  ,"CoreDeliveryDirectory"
  ,"CoreReleaseStartDate"
    )
  
  $ProjectName = [System.IO.Path]::GetFileName($PSScriptRoot)
  $ProjTopdir = $PSScriptRoot
  $ProjBuildPath = Join-Path $ProjTopdir "Build"
  $ProjDistPath = Join-Path $ProjTopdir "Dist"
  $ProjToolsPath = Join-Path $ProjTopdir "Tools"
  $script:config_vars += @(
   "ProjectName"
  ,"ProjTopdir"
  ,"ProjBuildPath"
  ,"ProjDistPath"
  ,"ProjToolsPath"
    )

  $ProjPackageListPath = Join-Path $ProjTopdir "${ProjectName}.lis"
  $ProjPackageZipPath = Join-Path $ProjDistPath  '${ProjectName}.${versionNum}.zip' #CONFIGURE: Expand dynamically versionNum not set
  $ProjDeliveryPath = Join-Path $PSScriptRoot "..\..\Deploy" #
  $zipArgs = 'a -bb2 -tzip "{0}" -ir0@"{1}"' -f $ProjPackageZipPath, $ProjPackageListPath         #CONFIGURE: Get paths from file
  
  $script:config_vars += @(
    "ProjPackageListPath"
     ,"ProjPackageZipPath"
     ,"ProjDeliveryPath"
     ,"ProjDeliveryPath"
     ,"zipArgs"
  )
  
  $ProjHistoryPath = Join-Path $ProjTopdir "${ProjectName}.git_history.txt"
  $ProjVersionPath = Join-Path $ProjTopdir "${ProjectName}.Build.Number"
  $ProjReadmePath   = Join-Path $ProjTopdir "README.md"
  $ProjHistorySinceDate ="2015-05-01"
  $script:config_vars += @(
    "ProjHistoryPath"
     ,"ProjVersionPath"
     ,"ProjHistorySinceDate"
     ,"ProjReadmePath"
  )
    
  <# Robocopy settings #>
  <# Tweek exDir exFile to define files to include in zip #>
  $exDir = @( "Build", "Dist", "tools", ".git", "specs", "Specification", "wrk", "work")
  $exFile = @("build.ps1", "build.psakefile.ps1", "*.nuspec", ".gitignore", "*.config.ps1", "*.lis", "*.nupkg", "*.Tests.ps1", "*.html", "*Pester*", "*.Tests.Setup.ps1", "*.zip", "*.rar")
  
  <# Custom additions #>
  #$exDir += @( ".Archive", ".SlickEdit")
  #$exFile +=  @( "*.build", "*.tt", "*(Original)*.*", "*.credential", "*.ttinclude", ".dir", "*.TempPoint.*")
  <# Customer additions #>
  
  #Quote the elements
  $XD = ($exDir | %{ "`"$_`"" }) -join " "
  $XF = ($exFile | %{ "`"$_`"" }) -join " "
  # Quote the RoboCopy Source and Target folders
  $RoboSrc = '"{0}"' -f $ProjTopdir
  $RoboTarget = '"{0}"' -f $ProjBuildPath
  $script:config_vars += @(
    "exDir"
    ,"exFile"
    ,"XD"
    ,"XF"
    ,"RoboSrc"
    ,"RoboTarget"
  )
  [boolean]$script:isErrors = $false
  Write-Host $('{0} ==> {1}' -f '$VerbosePreference', $VerbosePreference)
}

task default -depends build
task test-build -depends Show-Settings,      Clean-DryRun, create-dirs, git-history, set-version, compile
task      build -depends Show-Settings, git-status, clean, create-dirs, git-history, set-version, compile, tag-version, distribute




task Compile -description "Build Deliverable zip file" -depends create-dirs, set-version{
  $versionNum = Get-Content $ProjVersionPath
  $version = [system.Version]::Parse($versionNum)

  Write-Host "Attempting to get source files"

  $RoboArgs = @($RoboSrc, $RoboTarget, '/S', '/XD', $XD, '/XF', $XF)
  Write-Host $('Robocopy.exe {0}' -f $RoboArgs -join " ")
  try
  {
    Ruusty.ReleaseUtilities\start-exe "Robocopy.exe" -ArgumentList $RoboArgs #-workingdirectory $ProjBuildPath
  }
  catch [Exception] {
    write-Host "`$LastExitCode=$LastExitCode`r`n"
    if ($LastExitCode -gt 7)
    {
      $errMsg = $_ | fl * -Force | Out-String
      Write-host $errMsg
      Write-Error $_.Exception
    }
  }

  #Put the History and version in the build folder.
  Write-Host "Attempting get on $ProjHistoryPath, $ProjVersionPath"
  foreach ($i  in @($ProjHistoryPath, $ProjVersionPath))
  {
    Copy-Item -path $i -Destination $ProjBuildPath
  }
  #rename README.md to 
  Write-Host "Attempting get on $ProjReadmePath"
  foreach ($i  in @( $ProjReadmePath))
  {
    Copy-Item -path $i -Destination $(Join-Path $ProjBuildPath "README.${ProjectName}.md")
  }
  
  Write-Host "Attempting Versioning Pl/Sql in $ProjBuildPath"
    $plsqlVersionPath = Join-Path $ProjBuildPath "990_Version-pon.oms.sql"
    if (Test-Path $plsqlVersionPath)
    {
      Ruusty.ReleaseUtilities\Set-Token -Path $plsqlVersionPath -key 'ProductVersion' -value $versionNum
    }
    
  Write-Host "Attempting Versioning Markdown in $ProjBuildPath"
  Get-ChildItem -Recurse -Path $ProjBuildPath -Filter "*.md" | %{
    Ruusty.ReleaseUtilities\Set-VersionReadme -Path $_.FullName -version $version -datetime $now
  }

  Write-Host "Attempting to Convert Markdown to Html"
  md2html\Convert-Markdown2Html -path $ProjBuildPath -recurse -verbose:$IsVerbose
  
  $zipArgs = $ExecutionContext.InvokeCommand.ExpandString($zipArgs)
  Write-Host "Attempting to create zip file with: $zipArgs"
  
 # if (Test-Path -Path $ProjPackageZipPath -Type Leaf){ Remove-Item -path $ProjPackageZipPath}
  Ruusty.ReleaseUtilities\start-exe $7zipExe -ArgumentList $zipArgs -workingdirectory $ProjBuildPath
  
}


Task Distribute -description "Distribute the deliverables to Deliver" -PreCondition { ($isMaster) } -depends DistributeTo-Deploy {
  Write-Host -ForegroundColor Magenta "Done distributing deliverables"
}


task DistributeTo-Deploy -description "Copy Deliverables to the Deploy folder" {
  $versionNum = Get-Content $ProjVersionPath
  $DeliveryCopyArgs = @{
    path   = @("$ProjDistPath/*.zip" )
    destination = $ExecutionContext.InvokeCommand.ExpandString($ProjDeliveryPath)
    Verbose = $IsVerbose
  }
  Write-Host $("Attempting to copy deliverables to {0}" -f $DeliveryCopyArgs.Destination)
  if (!(Test-Path $DeliveryCopyArgs.Destination)) { mkdir -Path $DeliveryCopyArgs.Destination }
  Copy-Item @DeliveryCopyArgs
  dir $DeliveryCopyArgs.destination | out-string | write-host
}


task clean-dirs {
  if ((Test-Path $ProjBuildPath)) { Remove-Item $ProjBuildPath -Recurse -force }
  if ((Test-Path $ProjDistPath)) { Remove-Item $ProjDistPath -Recurse -force }
}


task create-dirs {
  if (!(Test-Path $ProjBuildPath)) { mkdir -Path $ProjBuildPath }
  if (!(Test-Path $ProjDistPath)) { mkdir -Path $ProjDistPath }
}


task clean -description "Remove all generated files" -depends clean-dirs {
  exec { & $GitExe "ls-files" --others --exclude-standard |ForEach-Object{ remove-item $_ -Verbose:$IsVerbose}}
}


Task Clean-DryRun -description "Remove all generated files" -depends clean-dirs {
  exec { & $GitExe "ls-files" --others --exclude-standard | ForEach-Object{ remove-item $_ -whatif}}
}

task set-version -description "Create the file containing the version" {
  $version = Ruusty.ReleaseUtilities\Get-Version -Major $ProjMajorMinor.Split(".")[0] -minor $ProjMajorMinor.Split(".")[1]
  Set-Content $ProjVersionPath $version.ToString()
  Write-Host $("Version:{0}" -f $(Get-Content $ProjVersionPath))
}


task tag-version -description "Create a tag with the version number" -PreCondition { $isMaster } {
  $versionNum = Get-Content $ProjVersionPath
  exec { & $GitExe "tag" "V$versionNum" }
}


task Display-version -description "Display the current version" {
  $versionNum = Get-Content $ProjVersionPath
  Write-Host $("Version:{0}" -f $versionNum)
}


task git-revision -description "" {
  exec { & $GitExe "describe" --tag }
}


task git-history -description "Create git history file" {
  exec { & $GitExe "log"  --since="$ProjHistorySinceDate" --pretty=format:"%h - %an, %ai : %s" } | Set-Content $ProjHistoryPath
}


task git-status -description "Stop the build if there are any uncommitted changes" -PreCondition { $isMaster }  {
  $rv = exec { & $GitExe status --short  --porcelain }
  $rv | write-host

  #Extras
  #exec { & git.exe ls-files --others --exclude-standard }

  if ($rv)
  {
    throw $("Found {0} uncommitted changes" -f ([array]$rv).Count)
  }
}


task Show-deliverable-Deliver -description "Show location of deliverables and open Explorer at that location" {
  $versionNum = Get-Content $ProjVersionPath
  $Spec = $ExecutionContext.InvokeCommand.ExpandString($ProjDeliveryPath)
  Write-Host $('Deliverable here : {0}' -f $Spec)
  exec { & cmd.exe /c explorer.exe $Spec }
  dir $Spec | out-string | write-host
}


task Show-Settings -description "Display the psake configuration properties variables"   {
  Write-Verbose("Verbose is on")
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive -unique | Format-Table -property name, value -autosize | Out-String -Width 2000 | Out-Host
}


task Show-SettingsVerbose -description "Display the psake configuration properties variables as a list"   {
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive -unique | format-list -Expand CoreOnly -property name, value | Out-String -Width 2000 | Out-Host
}


task set-buildList -description "Generate the list of files to go in the zip deliverable" {
  #Create file containing the list of files to zip. Check it into git.
  $scratchFile = Join-Path -path $env:TMP -ChildPath $([System.IO.Path]::GetRandomFileName())
  $RoboCopyLog = Join-Path -Path $env:TMP -ChildPath $('RoboCopyLog-{0}.txt' -f $([System.IO.Path]::GetRandomFileName()))
  #Create a random empty directory
  $RoboTarget = Join-Path -path $env:TMP -ChildPath $([System.IO.Path]::GetRandomFileName())
  mkdir $RoboTarget
  $RoboArgs = @($RoboSrc, $RoboTarget, '/S', '/XD', $XD ,'/XF' ,$XF ,'/L' ,$('/LOG:{0}'-f $RoboCopyLog) ,'/FP','/NDL' ,'/NP','/X')
  Write-Host $('Robocopy.exe {0}' -f $RoboArgs -join " ")

  try
  {
    Ruusty.ReleaseUtilities\start-exe "Robocopy.exe" -ArgumentList $RoboArgs #-workingdirectory $ProjBuildPath
  }
  catch [Exception] {
    write-Host "`$LastExitCode=$LastExitCode`r`n"
    if ($LastExitCode -gt 7)
    {
      $errMsg = $_ | fl * -Force | Out-String
      Write-host $errMsg
      Write-Error $_.Exception
    }
  }

  $matches = (Select-String -simple -Pattern "    New File  " -path $RoboCopyLog).line
  $csv = $matches | ConvertFrom-Csv -Delimiter "`t" -Header @("H1", "H2", "H3", "H4", "H5")
  $pathPrefix = ($RoboSrc.Trim('"')).Replace("/", "\").Replace("\", "\\") + "\\"
  Write-Verbose "Removing PathPrefix $pathPrefix from $RoboCopyLog"

  #Remove the Absolute Path prefix
  ($csv.h5) | set-content -Path $scratchFile
  @((Split-Path -path $ProjHistoryPath -Leaf), (Split-Path -path $ProjVersionPath -Leaf)) | Add-Content -path $scratchFile
  $lines = Get-Content $scratchFile
  ($lines) -creplace $pathPrefix, "" | set-content -Path $scratchFile
  #Add back the html files from markdown files
  $html = (Select-String  "\.md$" $scratchFile).line
  $html -creplace "\.md$", ".html" | Add-Content -path $scratchFile
  Get-Content $scratchFile | Sort-Object -Unique | Set-Content -path $ProjPackageListPath
  Write-Host -ForegroundColor Magenta "Done Creating : $ProjPackageListPath"
}


task help -Description "Helper to display task info" -alias "?" {
  Invoke-psake -buildfile $me -detaileddocs -nologo
  Invoke-psake -buildfile $me -docs -nologo
}

