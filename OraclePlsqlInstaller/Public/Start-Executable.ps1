<#
  .DESCRIPTION
    Use this function when executing sqlplus.exe
    Powershell incorrectly munges the command line.

  .EXAMPLE 
    $cmdLine = @("-L")
    $cmdLine += @("/@{0}" -f $cfg_local)
    $cmdLine += @('@"{0}"' -f $SqlPathCustomAbs)
    $cmdLine += @('"{0}"' -f $JobReportLogPath)
    $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
    $spArgs = @{"FilePath" = "sqlplus.exe";  "ArgumentList" = $cmdLine    }
    Start-Executable @spArgs -verbose

  .EXAMPLE 
    $cmdLine=  '-L "/@PONU.WORLD" @"OMS-POWERON\Update-FeederProfile.sql" "D:\Data.UAT\OMS-POWERON_Update-FeederProfile\OMS-POWERON_Update-FeederProfile.2017-01-03T12-40.log" "01/2017"'
    $spArgs = @{"FilePath" = "sqlplus.exe";  "ArgumentList" = $cmdLine    }
    Start-Executable @spArgs

  .NOTES
    Correctly sets the $LASTEXITCODE
  
    Throws an exception if the $LASTEXITCODE is not equal to zero

  http://windowsitpro.com/powershell/running-executables-powershell
#>

<#
  .SYNOPSIS
    Starts an exe with exitcode return
  
  .DESCRIPTION
    A detailed description of the Start-Executable function.
  
  .PARAMETER FilePath
    A description of the FilePath parameter.
  
  .PARAMETER ArgumentList
    A description of the ArgumentList parameter.
  
  .EXAMPLE
    		PS C:\> Start-Executable
  
  .NOTES
    Additional information about the function.
https://msdn.microsoft.com/en-us/library/system.diagnostics.process.standarderror(v=vs.110).aspx
http://stackoverflow.com/questions/24370814/how-to-capture-process-output-asynchronously-in-powershell
#>
function Start-Executable
{
  [CmdletBinding(SupportsShouldProcess = $true)]
  param
  (
    [Parameter(Position = 1)]
    [String]$FilePath,
    [Parameter(Position = 2)]
    [String[]]$ArgumentList
  )
  #region Initialization code
  $PSBoundParameters | format-list -Expand CoreOnly -Property Keys, Values | Out-String | Write-Verbose
  
  foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
  {
    $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
  }
  #endregion Initialization code
  If ($PSCmdlet.ShouldProcess($("{0} {1}" -f $FilePath, $($ArgumentList -join " "))))
  {
    $OFS = " "
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = $ArgumentList
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.RedirectStandardOutput = $true
    
    if ($process.Start())
    {#This is sychronous
      $output = $process.StandardOutput.ReadToEnd() -replace "\r\n$", ""
      if ($output)
      {
        if ($output.Contains("`r`n"))
        {
          $output -split "`r`n"
        }
        elseif ($output.Contains("`n"))
        {
          $output -split "`n"
        }
        else
        {
          $output
        }
      }
      $process.WaitForExit()
    }
  }
  else
  { $process = @{ ExitCode = 0 } }
  & "$Env:SystemRoot\system32\cmd.exe" /c exit $process.ExitCode
  if ($process.ExitCode -ne 0)
  {
    $e = [System.Management.Automation.RuntimeException]$("{0} ExitCode:{1}" -f $FilePath, $process.ExitCode)
    Write-Error -exception $e -Message $("{0} process.ExitCode {1}" -f $FilePath, $process.ExitCode) -TargetObject $FilePath -category "InvalidResult"
    throw $e
  }
}

