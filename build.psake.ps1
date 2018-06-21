<#
.SYNOPSIS
 This is a psake script

.DESCRIPTION
  Build a deliveable and packaging with Chocolatey.
  $ProjectName = [System.IO.Path]::GetFileName($PSScriptRoot)

#>
Framework '4.0'
Set-StrictMode -Version 4
$me = $MyInvocation.MyCommand.Definition
filter Skip-Empty { $_ | ?{ $_ -ne $null -and $_ } }

FormatTaskName "`r`n[------{0}------]`r`n"

Import-Module Ruusty.ReleaseUtilities
import-module md2html

properties {
  $script:config_vars = @()
  # Add variable names to $config_vars to display their values
  $script:config_vars += @(
      "GlobalPropertiesName"
     ,"GlobalPropertiesPath"
  )
  $whatif = $false;
  $now = [System.DateTime]::Now
  $Branch = & { git symbolic-ref --short HEAD }
  $isMaster = if ($Branch -eq 'master') {$true} else {$false}
  write-verbose($("CurrentLocation={0}" -f $executionContext.SessionState.Path.CurrentLocation))
  $GlobalPropertiesName=$("GisOms.Chocolatey.properties.{0}.xml" -f $env:COMPUTERNAME)
  $GlobalPropertiesPath = Ruusty.ReleaseUtilities\Find-FileUp "GisOms.Chocolatey.properties.${env:COMPUTERNAME}.xml" -verbose
  Write-Host $('$GlobalPropertiesPath:{0}' -f $GlobalPropertiesPath)
  $GlobalPropertiesXML = New-Object XML
  $GlobalPropertiesXML.Load($GlobalPropertiesPath)
  $script:config_vars += @(
  "whatif"
  ,"now"
  ,"Branch"
  ,"isMaster"
    )


  $GitExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='git.exe']").value
  $7zipExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='tools.7zip']").value
  $ChocoExe = $GlobalPropertiesXML.SelectNodes("/project/property[@name='tools.choco']").value
  $ProjMajorMinor = $GlobalPropertiesXML.SelectNodes("/project/property[@name='GisOms.release.MajorMinor']").value
  $CoreDeliveryDirectory = $GlobalPropertiesXML.SelectNodes("/project/property[@name='core.delivery.dir']").value
  $CoreChocoFeed = $GlobalPropertiesXML.SelectNodes("/project/property[@name='core.delivery.chocoFeed.dir']").value
  $CoreReleaseStartDate = $GlobalPropertiesXML.SelectNodes("/project/property[@name='GisOms.release.StartDate']").value
  $SpatialGitHubPath = $GlobalPropertiesXML.SelectNodes("/project/property[@name='Spatial_GitHub.Path']").value
  $script:config_vars += @(
  ,"GitExe"
  ,"7zipExe"
  ,"ChocoExe"
  ,"ProjMajorMinor"
  ,"CoreDeliveryDirectory"
  ,"CoreChocoFeed"
  ,"CoreReleaseStartDate"
  ,"SpatialGitHubPath"
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
  $ProjPackageZipPath  = Join-Path $ProjToolsPath  "${ProjectName}.zip"
  $ProjDeliveryPath= Join-Path $CoreDeliveryDirectory "GisOms"
  $ProjDeliveryPath = Join-Path $(Join-Path $ProjDeliveryPath ${ProjectName})  '${versionNum}'  #Expand dynamically versionNum not set
  #$ProjPackageZipVersionPath = Join-Path $ProjDeliveryPath  '${ProjectName}.${versionNum}.zip' #Expand dynamically versionNum not set
  $ProjPackageZipVersionPath = Join-Path $ProjDeliveryPath  "${ProjectName}.zip"
  $script:config_vars += @(
  "ProjPackageListPath"
  ,"ProjPackageZipPath"
  ,"ProjDeliveryPath"
  ,"ProjDeliveryPath"
  ,"ProjPackageZipVersionPath"
)



  $ProjHistoryPath = Join-Path $ProjTopdir "${ProjectName}.git_history.txt"
  $ProjVersionPath = Join-Path $ProjTopdir "${ProjectName}.Build.Number"
  $ProjNuspecName = "ched-${ProjectName}"
  $ProjNuspec = "${ProjNuspecName}.nuspec"
  $ProjNuspecPath = Join-Path $ProjTopdir "${ProjNuspecName}.nuspec"
  $ProjNuspecPkgVersionPath = Join-Path $ProjTopdir  '${ProjNuspecName}.${versionNum}.nupkg'
  $ProjHistorySinceDate ="2015-05-01"
  $script:config_vars += @(
     "ProjHistoryPath"
    ,"ProjVersionPath"
    ,"ProjNuspecName"
    ,"ProjNuspecPath"
    ,"ProjNuspecPkgVersionPath"
    ,"ProjHistorySinceDate"
     ,"ProjPackageZipVersionPath"
    ,"ProjNuspec"
      )
  
  Set-Variable -Name "sdlc" -Description "System Development Lifecycle Environment" -Value "UNKNOWN"
  $sdlcs = @('prod', 'uat','test','dev') #nupkg specific to a SDLC
  $sdlcs = @('ALL')                      #nupkg does all SDLCs

  $zipArgs = 'a -bb2 -tzip "{0}" -ir0@"{1}"' -f $ProjPackageZipPath, $ProjPackageListPath # Get paths from file
  #$zipArgs = 'a -bb2 -tzip "{0}" -ir0!*' -f $ProjPackageZipPath #Everything in $ProjBuildPath
    $script:config_vars += @(
     ,"zipArgs"
     ,"sdlc"
    ,"sdlcs"
  )
  
  <# Robocopy settings #>
  <# Tweek exDir exFile to define files to include in zip #>
  $exDir = @("$ProjTopdir\src\.TEMPLATE", "Build", "Dist", "tools", ".git", "specs", "Specification", "wrk", "work")
  $exFile = @("build.bat", "build.psake.ps1", "*.nuspec", ".gitignore", "*.config.ps1", "*.lis", "*.nupkg", "*.Tests.ps1", "*.html", "*Pester*", "*.Tests.Setup.ps1")
  #Quote the elements
  $XD = ($exDir | %{ "`"$_`"" }) -join " "
  $XF = ($exFile | %{ "`"$_`"" }) -join " "
  # Quote the RoboCopy Source and Target folders
  $RoboSrc = '"{0}\OraclePlsqlInstaller"' -f $ProjTopdir
  $RoboTarget = '"{0}\OraclePlsqlInstaller"' -f $ProjBuildPath
  $script:config_vars += @(
    "exDir"
    ,"exFile"
    ,"XD"
    ,"XF"
    ,"RoboSrc"
     ,"RoboTarget"
  )
  
  Write-Verbose "Verbose is ON"
  Write-Host $('{0} ==> {1}' -f '$VerbosePreference', $VerbosePreference)
}

task default -depends build
task test-build -depends Show-Settings, clean,             create-dirs, git-history, set-version, compile, compile-nupkg
task      build -depends Show-Settings, git-status, clean, create-dirs, git-history, set-version, compile, compile-nupkg, tag-version, distribute



task Compile -description "Build Deliverable zip file" -depends clean, create-dirs, set-version   {
  $versionNum = Get-Content $ProjVersionPath
  $version = [system.Version]::Parse($versionNum)
    
  Write-Verbose "Verbose is on"
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
  
  foreach ($i  in @($ProjHistoryPath, $ProjVersionPath))
  {
    Copy-Item -path $i -Destination $ProjBuildPath
  }
  
  Write-Host "Attempting Versioning"
  $MdPathSpec = $(Join-Path -Path $ProjBuildPath -ChildPath "*.md")
  Write-Host "Attempting Versioning Markdown $MdPathSpec in $ProjBuildPath"
  Resolve-Path -Path $MdPathSpec | %{
    Ruusty.ReleaseUtilities\Set-VersionReadme $_.Path  $version  $now
  }
  
  Write-Host "Attempting to Convert Markdown to Html"
  md2html\Convert-Markdown2Html -path $ProjBuildPath -recurse -verbose
  
  Write-Host "Attempting to create zip file with '$zipArgs'"
  if (Test-Path -Path $ProjPackageZipPath -Type Leaf){ Remove-Item -path $ProjPackageZipPath}
  Ruusty.ReleaseUtilities\start-exe $7zipExe -ArgumentList $zipArgs -workingdirectory $ProjBuildPath
  #Copy README and history
  Copy-Item -Path $(Join-Path $ProjBuildPath "README.html") -Destination $ProjDistPath
  Copy-Item -Path $ProjHistoryPath -Destination $ProjDistPath
}


Task Compile-nupkg -description "Compile Chocolatey nupkg from nuspec" -depends compile-nupkg-single, compile-nupkg-multi {
  Write-Host -ForegroundColor Magenta "Done compiling Chocolatey packages"
}


task Compile-nupkg-single -description "Compile single Chocolatey nupkg from nuspec" -PreCondition { ($sdlcs.Count -eq 1) }  {
  $versionNum = Get-Content $ProjVersionPath
  Write-Host $("Compiling {0}" -f $ProjNuspecPath)
  exec { & $ChocoExe pack $ProjNuspecPath --version $versionNum }
}


task Compile-nupkg-multi -description "Compile Multiple Chocolatey sdlc nupkg from nuspec" -PreCondition { ($sdlcs.Count -gt 1)} {
  $versionNum = Get-Content $ProjVersionPath
  Write-Host $("Compiling {0}" -f $ProjNuspecPath)
  foreach ($sdlc in $sdlcs)
  {
    Write-Host "Attempting to get Chocolatey Install Scripts for $sdlc"
    Copy-Item -path "tools" -Destination $ProjDistPath -Recurse -force
    Ruusty.ReleaseUtilities\Set-Token -Path $(join-path $ProjDistPath "tools/properties.ps1") -key "SDLC" -value $sdlc
    
    Write-Host "Attempting to get *.nuspec  for $sdlc"
    Copy-Item -path $ProjNuspecPath -Destination $ProjDistPath
    Ruusty.ReleaseUtilities\Set-Token -Path $(join-path $ProjDistPath $ProjNuspec) -key "SDLC" -value $sdlc
    Ruusty.ReleaseUtilities\Set-Token -Path $(join-path $ProjDistPath $ProjNuspec) -key "SDLC_SUFFIX" -value "-${sdlc}"
    
    exec { & $ChocoExe pack $(join-path $ProjDistPath $ProjNuspec) --version $versionNum --outputdirectory $ProjDistPath }
  }
}


task Distribute -description "Distribute the deliverables to Deliver" -PreCondition { ($isMaster) } -depends distributeTo-Delivery, distribute-nupkg-single, distribute-nupkg-multi {
  Write-Host -ForegroundColor Magenta "Done distributing deliverables"
}


task DistributeTo-Delivery -description "Copy Deliverables to the Public Delivery Share" {
  $versionNum = Get-Content $ProjVersionPath
  $DeliveryCopyArgs = @{
    path   = @("$ProjDistPath/*.zip", "$ProjDistPath/README.*", "$ProjDistPath/*.nupkg","$ProjDistPath/tools/*.zip",$ProjHistoryPath)
    destination = $ExecutionContext.InvokeCommand.ExpandString($ProjDeliveryPath)
    Verbose = $VerbosePreference
  }
  Write-Host $("Attempting to copy deliverables to {0}" -f $DeliveryCopyArgs.Destination)
  if (!(Test-Path $DeliveryCopyArgs.Destination)) { mkdir -Path $DeliveryCopyArgs.Destination }
  Copy-Item @DeliveryCopyArgs
  dir $DeliveryCopyArgs.destination | out-string | write-host
}


task Distribute-nupkg-single -description "Push nupkg to Chocolatey Feed" -PreCondition { ($sdlcs.Count -eq 1) } {
  $versionNum = Get-Content $ProjVersionPath
  $nupkg = $ExecutionContext.InvokeCommand.ExpandString($ProjNuspecPkgVersionPath)
  Write-Host $("Pushing {0}" -f $nupkg)
  exec { & $ChocoExe  push $nupkg -s $CoreChocoFeed }
}


task Distribute-nupkg-multi -description "Push multiple sdlc nupkg to Chocolatey Feed" -PreCondition { ($sdlcs.Count -gt 1) } {
  $versionNum = Get-Content $ProjVersionPath
  Push-Location $ProjDistPath
  foreach ($sdlc in $sdlcs)
  {
    $LocalNuspecPkgVersionName = '${ProjNuspecName}-${sdlc}.${versionNum}.nupkg'
    $nupkg = $ExecutionContext.InvokeCommand.ExpandString($LocalNuspecPkgVersionName)
    Write-Host $("Pushing {0}" -f $nupkg)
    exec { & $ChocoExe  push $nupkg -s $CoreChocoFeed }
  }
  Pop-Location
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
  if ($isMaster)
  {
    exec { & $GitExe "clean" -X -f } 
  }
  else
  {
    exec { & $GitExe "clean" -X -f --dry-run } 
  }
}


task set-version -description "Create the file containing the version" {
  $version = Ruusty.ReleaseUtilities\Get-Version -Major $ProjMajorMinor.Split(".")[0] -minor $ProjMajorMinor.Split(".")[1]
  Set-Content $ProjVersionPath $version.ToString()
  Write-Host $("Version:{0}" -f $(Get-Content $ProjVersionPath))
}


task set-versionAssembly -description "Version the AssemblyInfo.cs" {
  $versionNum = Get-Content $ProjVersionPath
  $version = [system.Version]::Parse($versionNum)
  Ruusty.ReleaseUtilities\Set-VersionAssembly "CmdletRuusty\Properties\AssemblyInfo.cs" $version
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


Task Show-Choco-Deliverable -description "Show the Chocolatey nupkg packages/s in the chocolatey Feed (Assumes hosted on a UNC path)"{
  $versionNum = Get-Content $ProjVersionPath
  $LocalNuspecPkgVersionName = $ExecutionContext.InvokeCommand.ExpandString('${ProjNuspecName}*.${versionNum}.nupkg')
  $Spec = Join-Path -path $CoreChocoFeed -childpath $LocalNuspecPkgVersionName
  Write-Host $('Chocolatey goodness here : {0}' -f $Spec)
  dir $Spec | out-string | write-host
  (resolve-path $Spec).ProviderPath | out-string | write-host
}


task Show-Settings -description "Display the psake configuration properties variables"   {
  Write-Verbose("Verbose is on")
  Get-Variable -name $script:config_vars -ea Continue | sort -Property name -CaseSensitive -unique | Format-Table -property name, value -autosize | Out-String -Width 2000 | Out-Host
}


task Show-SettingsVerbose -description "Display the psake configuration properties variables as a list"   {
  Write-Verbose("Verbose is on")
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

task ? -Description "Helper to display task info" -depends help {
}


task help -Description "Helper to display task info" {
  Invoke-psake -buildfile $me -detaileddocs -nologo
  Invoke-psake -buildfile $me -docs -nologo
}


<#
task Test -description "Pester tests"{
  $verbose = $false
  $result = invoke-pester -Script @{ Path = '.\src\SpaOmsGis.Tests.ps1'; Parameters = @{ Verbose = $false } } -OutputFile ".\src\SpaOmsGis.Tests.TestResults.xml" -PassThru -Verbose:$verbose
  Write-Host $result.FailedCount
  if ($result.FailedCount -gt 0)
  {
    Write-Error -Message $("Pester failed {0} tests" -f $result.FailedCount)
  }
}
#>


#Task getDependencies -description "Get shared dependencies from Git" {
#  #region  Get the file the Spatial_GitHub 
#  Write-Host "Attempting to get Get-GisOmsSdlc.ps1"
#  GisOmsUtils\Get-GitFile -gitRemote $(join-path -path $SpatialGitHubPath -child "ChocoPkgContents/PSGisOmsRelease.git" ) -gitBranch "master" -gitFilePath "GisOmsRelease\Public\Get-GisOmsSdlc.ps1" -destPath $ProjBuildPath -verbose
#  Move-Item $(Join-Path $ProjBuildPath "GisOmsRelease\Public\Get-GisOmsSdlc.ps1") $(Join-Path $ProjTopdir "tools/Get-GisOmsSdlc.ps1") -Force
#  remove-item   $(Join-Path $ProjBuildPath 'GisOmsRelease') -Recurse
#}
