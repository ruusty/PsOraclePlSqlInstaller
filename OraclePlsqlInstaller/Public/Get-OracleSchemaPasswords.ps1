function Get-OracleSchemaPasswords
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    $sqlFileInfo
  )
  BEGIN 
  {
  	""
  }
  PROCESS
  {
    $credentialPaths = $sqlFileInfo | %{ $_.pwdFname } | sort -Unique
    foreach ($pwdFname in $credentialPaths)
    {
      if (Test-Path "..\$pwdFname") { $pwdFname = "..\$pwdFname" }
      if (Test-Path $pwdFname)
      {
        Write-Verbose "Getting credentials from $pwdFname"
      }
      else
      {
        #create the credential file as it doesnt exist
        $name = [System.IO.Path]::GetFileNameWithoutExtension($pwdFname)
        if ($name -match '^([A-Za-z_]+)@([A-Za-z0-9_\.]+$)')
        {
          $user = $matches[1]
          $connect_identifier = $matches[2]
        }
        #Prompt for the credentials and save
        [pscredential]$Credential = $(Get-Credential -UserName $user -Message "Enter Oracle $user Password for $connect_identifier")
        if (!$Credential) { exit }
        $credPath = Join-Path -Path $PSScriptRoot -ChildPath $($user + "`@$connect_identifier.credential")
        $Credential | Export-CliXml $credPath
      }
    }
  }
}
