<#
  .SYNOPSIS
    Set the Oracle schema passwords
  
  .DESCRIPTION
    Gets the Oracle schema passwords from the credential file, 
    If the credential file doesn't exist, prompt for the password and create it

    The credential file can live in current working directory or parent of working directory
   
  .EXAMPLE
    PS C:\> Set-OracleSchemaPassword -sqlPlusCommand $value1
  
#>
function Set-OracleUserPassword
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               ValueFromPipeline = $true,
               Position = 0)]
    [PSTypeName('PSOracle.SqlPlusCmd')]
    $sqlPlusCommand
  )
  BEGIN
  {
    #region Initialization code
    $PSBoundParameters | format-list -Expand CoreOnly -Property Keys, Values | Out-String | Write-Verbose
    foreach ($Parameter in (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters)
    {
      $("Attempting " + $PSCmdlet.MyInvocation.InvocationName), $(Get-Variable -Name $Parameter.Values.Name -ErrorAction SilentlyContinue) | Out-String | write-verbose
    }
    Write-Verbose $("in-process {0}" -f $PSCmdlet.MyInvocation.InvocationName)
    #endregion Initialization code
  }
  PROCESS
  {
    $pwdFname = $sqlPlusCommand.credentialFileName
    $parentPwdDir = Split-Path -Parent -Path $sqlPlusCommand.credentialFileName
    $parentPwdDir = Split-Path -Parent -Path $parentPwdDir
    $parentPwdFname = Join-Path $parentPwdDir $([System.IO.Path]::GetFileName($sqlPlusCommand.credentialFileName))
    if (Test-Path $parentPwdFname) { $pwdFname = $parentPwdFname }
    if ($pwdFname -and (Test-Path $pwdFname))
    {
      Write-Verbose "$pwdFname exists"
      $sqlPlusCommand.credentialFileName = $pwdFname
    }
    else
    {
      Write-Verbose $('Creating {0}' -f $sqlPlusCommand.credentialFileName ) 
      #create the credential file as it doesn't exist, get the name from the file
      $credFname = [System.IO.Path]::GetFileNameWithoutExtension($sqlPlusCommand.credentialFileName)
      if ($credFname -match '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)')
      {
        $user = $matches[1]
        $connect_identifier = $matches[2]
      }
      else
      {
        throw "Invalid Credential file name"
      }
      #Prompt for the credentials and save
      $Msg = 'Enter Oracle {0} Password for {1}' -f $sqlPlusCommand.OraUser , $sqlPlusCommand.tnsName
      [pscredential]$Credential = $(Get-Credential -UserName $sqlPlusCommand.OraUser -Message $Msg)
      if (!$Credential) { throw "Null credentials entered" }
      $Credential | Export-CliXml $sqlPlusCommand.credentialFileName
    }
    $sqlPlusCommand
  }
}
