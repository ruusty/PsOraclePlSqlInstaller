<#
  .SYNOPSIS
    Creates fixtures from templates
  
  .DESCRIPTION
    Creates fixtures from templates
    for building and executing a deliverable
  
  .PARAMETER Destination
    Directory
  
  .PARAMETER Force
    Overwrite and existing file
  
  .PARAMETER Filter
    Only create fixtures matching the filter wildcards
  
  .EXAMPLE
    New-Fixtures -whatif -filter build.bat -force

  .EXAMPLE
    New-Fixtures -whatif

#>
function New-Fixtures
{
  [CmdletBinding(SupportsShouldProcess = $true)]
  param
  (
    [Parameter(Position = 0)]
    [ValidateScript({ test-path -PathType Container $_ })]
    [string]$Destination = $PWD,
    [switch]$Force,
    [string]$Filter = '*'
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
  $FixtureNames = (get-item -Path $(Join-Path "$PSScriptRoot" "..\Data\*.*" )).FullName
  foreach ($i in $FixtureNames | Where-Object {[System.IO.Path]::GetFileName($_) -like $Filter})
  {
    $destPath = Join-Path -path $Destination -childpath $([System.IO.Path]::GetFileName($i))
    if ($Force -or !(Test-Path $destPath))
    {
      Get-Content -path $i | Set-Content -Path $destPath
    }
    else
    {
      Write-Host "File exists: $destPath"
    }
  }
}
