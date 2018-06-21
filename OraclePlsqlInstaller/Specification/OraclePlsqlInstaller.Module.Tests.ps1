<#
Module Tests
#>
[CmdletBinding()]
param
(
)
#region initialisation
$boolVerbose = $true

if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
{
  $VerbosePreference = 'Continue'
  $boolVerbose = $false
}
Write-Host $('{0}==>{1}' -f '$VerbosePreference', $VerbosePreference)
$PSBoundParameters | Out-String | Write-Verbose

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
$name = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
Write-Verbose $('{0}:{1}' -f '$here', $here)
Write-Verbose $('{0}:{1}' -f '$sut', $sut)
Write-Verbose $('{0}:{1}' -f '$sut', $sut)


$ModuleName = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace ".Module.Tests.ps1"
Write-Verbose $('{0}:{1}' -f '$ModuleName', $ModuleName)

$ModulePath = (Resolve-Path -path $(Join-Path $PSScriptRoot "..")).Path
Write-Verbose $('{0}:{1}' -f '$ModulePath', $ModulePath)

$ManifestPath = "$ModulePath\$ModuleName.psd1"
Write-Verbose $('{0}:{1}' -f '$ManifestPath', $ManifestPath)
#region setup dependencies

$ModuleSetup = Join-Path $PSScriptRoot "Pester.Tests.Setup.ps1"
if (Test-Path $ModuleSetup) { . $ModuleSetup }


$name = $ModuleName
Write-Verbose $('{0}:{1}' -f '$here', $here)
Write-Verbose $('{0}:{1}' -f '$sut', $sut)

#Explicitly import the module for testing
Import-Module $ModulePath -Force -ErrorAction Stop 
$(get-module $ModuleName).ExportedCommands | sort | Out-String | write-verbose

<#	
.DESCRIPTION
	The script lets you test the functions and other features of your module.

invoke-Pester -Script @{ Path = './OraclePlsqlInstaller.Module.Tests.ps1';   Parameters = @{ Verbose = $true;  } }
pester.bat -testname "IncompletePonProject" -Script @{ Path = './OraclePlsqlInstaller.Module.Tests.ps1'; Parameters = @{ Verbose = $true;  }}

#>



$script:sqlCommands = @()
#Run each module function
# pester -testname "OraclePlsqlInstaller" -Script @{ Path = './OraclePlsqlInstaller.Module.Tests.ps1'; Parameters = @{ Verbose = $true; } }

Describe "$ModuleName" {
  #Setup vars
  #$JobReportPath = Join-Path -path $DataDir -childPath $('Publish-IncompleteProjectReport.{0}' -f $(Get-Date -Format "yyyy-MM-ddTHH-mm"))
  $sdlc = "DEV"
  $IsoDateTimeStr= "yyyy-MM-ddTHH-mm-ss"
  $initArgs = @{
    directory        = $(Join-Path $PSScriptRoot "Data")
    sqlSpec          = @('[0-9_][0-9_][0-9_]_*-*.sql');
    logFileSuffix    = $IsoDateTimeStr;
    netServiceNames  = Set-SdlcConnections $sdlc.ToUpper();
    #verbose          = $boolVerbose;
  }
  
  Context "Execution"  {
    $Script:results = $null
    
    It "Should do something useful"{
      {
        $script:sqlCommands = Get-SqlPlusCommands @initArgs
      } | Should not throw
      
      #$script:sqlCommands | Out-String | write-verbose
    }
    
    It "Should do Validate Output" -Pending {
      {
        $script:sqlCommands = Get-SqlPlusCommands @initArgs
      } | Should not throw
      @($script:sqlCommands).GetEnumerator() | %{
        #TODO $script:sqlCommands
        Write-Host $_
      }

    }
    
    It "Should do Execute Whatif" {
      $zipExe = "7z.exe"
      $sqlplusExe = "sqlplus.exe"
      {
        $script:sqlCommands = Get-SqlPlusCommands @initArgs
      } | Should not throw
      
      @($script:sqlCommands).GetEnumerator() | %{
        Write-Host "Attempting : ", $sqlplusExe, $_.sqlplusArgs
        OraclePlsqlInstaller\Start-ExeWithOutput -FilePath $sqlplusExe -ArgumentList $_.sqlplusArgs  -whatif:$true
      }
    }
    
    
    It "Should do Test-Connections"  {
      {
        $script:sqlCommands | Test-OracleConnections -sqlplusExe "sqlplus.exe" 
      } | Should not throw
    }
    
  }
}

# test the module manifest - exports the right functions, processes the right formats, and is generally correct
# https://mattmcnabb.github.io/pester-testing-your-module-manifest

# invoke-pester -testname "Manifest" -Script @{ Path = './OraclePlsqlInstaller.Module.Tests.ps1'; Parameters = @{ Verbose = $true; } }
# because includes a nested binary module need to execute from Windows Console
# pester -testname "Manifest" -Script @{ Path = './OraclePlsqlInstaller.Module.Tests.ps1'; Parameters = @{ Verbose = $true; } }


Describe "Manifest" {
  
  $ManifestHash = Invoke-Expression (Get-Content $ManifestPath -Raw)
  
  It "has a valid manifest" {
    {
      $null = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop -WarningAction SilentlyContinue
    } | Should Not Throw
  }
  
  It "has a valid root module" {
    $ManifestHash.RootModule | Should Be "$ModuleName.psm1"
  }
  
  It "has a valid Description" {
    $ManifestHash.Description | Should Not BeNullOrEmpty
  }
  
  It "has a valid guid" {
    $ManifestHash.Guid | Should Match '[A-Za-z0-9]{4}([A-Za-z0-9]{4}\-?){4}[A-Za-z0-9]{12}' #'90EB765F-A568-486B-2DAA-E60C4C75D5AB'
  }
  
  #  It "has a valid prefix" {
  #    $ManifestHash.DefaultCommandPrefix | Should Not BeNullOrEmpty
  #  }
  
  It "has a valid copyright" {
    $ManifestHash.CopyRight | Should Not BeNullOrEmpty
  }
    
  It "Should exports cmdlet functions"  {
    $numCmdlet = 1
    $ExportedCommands = $(get-module $ModuleName).ExportedCommands
    $CmdletCount = ($ExportedCommands.GetEnumerator() | % { $_.value } | Where-Object { ($_.CommandType -eq 'Cmdlet') }).count
    $CmdletCount | Should be $numCmdlet
  }
  
  
  It "Should export public script functions" {
    $numFunctions = 10
    $ExportedCommands = $(get-module $ModuleName).ExportedCommands
    $Functions = $ExportedCommands.GetEnumerator() | % { $_.value } | Where-Object { ($_.CommandType -eq 'Function') }
    $FunctionCount = ($Functions).count
    $FunctionCount | Should be $numFunctions
    
  }
  
  # Check all files in public have correct function name
  It "Files in public have Should have correct function name"  {
    $ExportedCommands = $(get-module $ModuleName).ExportedCommands
    $Functions = $ExportedCommands.GetEnumerator() | % { $_.value } | Where-Object { ($_.CommandType -eq 'Function') }
    foreach ($FunctionName in $Functions)
    {
      $srcFile = Join-Path "$ModulePath\Public" "$FunctionName.ps1"
      Test-Path -Path $srcFile | Should Be $true
    }
  }
}
