<#
  .SYNOPSIS
    Starts an exe and waits to return with exitcode.

  .DESCRIPTION
    Want to asynchronously capture stdout and stderr and end up in stderr
  
  .PARAMETER FilePath
    Exe to execute
  
  .PARAMETER ArgumentList
    Exe arguments parameter.
  
  .PARAMETER WorkingDirectory
    A description of the WorkingDirectory parameter.
  
  .PARAMETER LogPath
    Standard output written to this filename
    Aliased to RedirectStandardOutput so this function is interchangeable with Start-Process

  
  .EXAMPLE 
    $cmdLine = @("-L")
    $cmdLine += @("/@{0}" -f $cfg_local)
    $cmdLine += @('@"{0}"' -f $SqlPathCustomAbs)
    $cmdLine += @('"{0}"' -f $JobReportLogPath)
    $cmdLine += @('"{0}"' -f $cfg_Sqlarg1)
    $spArgs = @{"FilePath" = "sqlplus.exe";  "ArgumentList" = $cmdLine    }
    Start-Exe @spArgs -verbose

  .EXAMPLE 
    $cmdLine=  '-L "/@PONU.WORLD" @"OMS-POWERON\Update-FeederProfile.sql" "D:\Data.UAT\OMS-POWERON_Update-FeederProfile\OMS-POWERON_Update-FeederProfile.2017-01-03T12-40.log" "01/2017"'
    $spArgs = @{"FilePath" = "sqlplus.exe";  "ArgumentList" = $cmdLine    }
    Start-Exe @spArgs

  .NOTES
    Correctly sets the $LASTEXITCODE
    Throws an exception if the $LASTEXITCODE is not equal to zero

  .LINK
    http://windowsitpro.com/powershell/running-executables-powershell

  .NOTES
    Use this function when executing sqlplus.exe as powershell munges the commandline
    Additional information about the function.
    https://msdn.microsoft.com/en-us/library/system.diagnostics.process.standarderror(v=vs.110).aspx
    http://stackoverflow.com/questions/24370814/how-to-capture-process-output-asynchronously-in-powershell
    https://msdn.microsoft.com/en-us/library/system.diagnostics.datareceivedeventhandler%28v=vs.110%29.aspx?f=255&MSPPError=-2147217396
    https://msdn.microsoft.com/en-us/library/system.diagnostics.datareceivedeventargs.data(v=vs.110).aspx
#>
function Start-Exe
{
  [CmdletBinding(SupportsShouldProcess = $true)]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    [String]$FilePath,
    [Parameter(Position = 2)]
    [String[]]$ArgumentList,
    [String]$WorkingDirectory = $null,
    [Alias('RedirectStandardOutput')]
    [String]$LogPath = $null
  )
  
  #$RedirectStandardOutput
  #region Initialization code
  $PSBoundParameters | format-list -Expand CoreOnly -Property Keys, Values | Out-String | Write-Verbose
  
  foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
  {
    $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
  }
  #endregion Initialization code
  
  $source = @"
using System;
using System.Diagnostics;
using System.IO;


namespace Proc.Start
{
    public static class Executable
    {
        static readonly object _locker = new object(); 
        public static int Start(string executable, string args = "", string cwd = "", string LogPath = "")
        {
            //Trace.WriteLine(string.Format("{0} {1} > {2}",executable ,args, LogPath));

            Process process = new Process();
            process.StartInfo.FileName = executable;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;

            //* Optional process configuration
            if (!String.IsNullOrEmpty(args)) { process.StartInfo.Arguments = args; }
            if ((!String.IsNullOrEmpty(cwd)) &&   Directory.Exists(cwd))  { 
              process.StartInfo.WorkingDirectory = cwd; 
            }

            bool isLogFileRedirect = false; 
            if (!String.IsNullOrEmpty(LogPath))
            {
                string LogParentPath = Directory.GetParent(LogPath).FullName;
                if ((!String.IsNullOrEmpty(LogParentPath)) && Directory.Exists(LogParentPath)) isLogFileRedirect = true;
            }

            //* Set output and error (asynchronous) handlers
            process.OutputDataReceived += (s, e) =>
            {
                if (isLogFileRedirect)
                {
                    lock (_locker)
                    {
                        File.AppendAllLines(LogPath, new string[] { e.Data });
                    }
                }
                Console.WriteLine(e.Data);
            };

            process.ErrorDataReceived += (s, e) =>
            {
                if (isLogFileRedirect){
                    lock (_locker)
                    {
                        File.AppendAllLines(LogPath, new string[] { "STDERR>", e.Data });
                    }
                }
                Console.WriteLine("STDERR>" + e.Data);
            };
            process.Exited += (s, e) =>
            {
                Console.WriteLine("Exit time:    {0}\r\n" + "Exit code:    {1}\r\n", process.ExitTime, process.ExitCode);
            };

            //* Start process and handlers
            try
            {
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.WaitForExit();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex.Message);
                return -1;
            }
            return process.ExitCode;
        }
    }
}
"@
  
  Add-Type -TypeDefinition $source -Language CSharp -Debug:$false
  
  If ($PSCmdlet.ShouldProcess($("{0} {1}" -f $FilePath, $($ArgumentList -join " "))))
  {
    $rc = [Proc.Start.Executable]::Start($FilePath, $($ArgumentList -join " "), $WorkingDirectory, $LogPath)
  }
  else
  { $rc = 0 }
  & "$Env:SystemRoot\system32\cmd.exe" /c exit $rc
  if ($rc -ne 0)
  {
    $e = [System.Management.Automation.RuntimeException]$("{0} ExitCode:{1}" -f $FilePath, $rc)
    Write-Error -exception $e -Message $("{0} process.ExitCode {1}" -f $FilePath, $rc) -TargetObject $FilePath -category "InvalidResult"
    throw $e
  }
}

