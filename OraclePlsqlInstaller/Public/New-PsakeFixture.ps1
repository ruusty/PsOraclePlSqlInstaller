<#
  .SYNOPSIS
    Psake file for Pl/Sql and Batch file wrapper
  
  .DESCRIPTION
    Psake file for Pl/Sql and Batch file wrapper
  
  .PARAMETER Destination
    Directory
  
  .PARAMETER Force
    A description of the Force parameter.
  
  .EXAMPLE
    PS C:\> New-OracleRunFixture
  
  .NOTES
    Additional information about the function.
#>
function New-PsakeFixture
{
  [CmdletBinding()]
  param
  (
    [Parameter(Position = 0)]
    [ValidateScript({ test-path -PathType Container $_ })]
    [string]$Destination = $PWD,
    [switch]$Force
  )
  
  #region setup
  # Get the command name
  $CommandName = $PSCmdlet.MyInvocation.InvocationName;
  # Get the list of parameters for the command
  "${CommandName}: Input", (((Get-Command -Name ($PSCmdlet.MyInvocation.InvocationName)).Parameters) |
    %{ Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue; } |
    Format-Table -AutoSize @{ Label = "Name"; Expression = { $_.Name }; }, @{ Label = "Value"; Expression = { (Get-Variable -Name $_.Name -EA SilentlyContinue).Value }; }) | Out-String | write-verbose
  #endregion
  Write-Verbose $('{0}=={1}' -f '$PSScriptRoot', $PSScriptRoot)
  
  #$runPlsql | Set-Content -Path $(Join-Path $folder "run.sql")  -Encoding Ascii
  $outPsakeName = "sqlplus.psake.ps1"
  
  $destPsakePath = Join-Path $Destination $outPsakeName
  if ($Force -or !(Test-Path $destPsakePath))
  {
    Get-Content -path $(Join-Path $PSScriptRoot "..\Data\$outPsakeName") | Set-Content -Path $destPsakePath
  }
  else
  {
    Write-Host "File exists: $destPsakePath"
  }
  
  $outInstallBatName = "Install.bat"
  $destInstallBatPath = Join-Path $Destination $outInstallBatName
  if ($Force -or !(Test-Path $destInstallBatPath))
  {
    Get-Content -path $(Join-Path $PSScriptRoot "..\Data\$outInstallBatName") | Set-Content -Path $destInstallBatPath
  }
  else
  {
    Write-Host "File exists: $destInstallBatPath"
  }
}
