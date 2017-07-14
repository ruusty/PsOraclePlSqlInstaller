function Set-SdlcConnections
<#
  .SYNOPSIS
    Set the SDLC
  
  .DESCRIPTION
    set and verify the SDLC Oracle Connection strings
  
  .PARAMETER sdlc_environment
    A description of the sdlc_environment parameter.
  
  
  .EXAMPLE
    		PS C:\> Set-SDLC_Connection -sdlc DEV 
  
  .NOTES
    Additional information about the function.
#>
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    [ValidateSet('DEV', 'TEST', 'UAT', 'PROD','UNKNOWN')]
    [string]$sdlc ='UNKNOWN'
  )
  switch -case ($sdlc)
  {
    DEV  {
      $netServiceNames = @{ pon = "POND.world"; onc = "ONCD.world"; sweg = "SWEG43D.world" }; break
    }
    TEST {
      $netServiceNames = @{ pon = "PONT.world"; onc = "ONCT.world" }; break
    }
    UAT  {
      $netServiceNames = @{ pon = "PONU.world"; onc = "ONCU.world"; sweg = "SWEG43U.world" }; break
    }
    PROD {
      $netServiceNames = @{ pon = "PONP.world"; onc = "ONCP.world"; sweg = "SWEG43P.world" }; break
    }
    UNKNOWN {
      $netServiceNames = @{ pon = "PONX.world"; onc = "ONCX.world"; sweg = "SWEG43X.world" }; break
    }
    default { throw "Unknown environment"; break }
  }
  $netServiceNames.GetEnumerator() | Sort-Object Name | % {
    write-verbose("$netServiceNames {0} : {1} " -f $_.name, $_.value)
  }
  $netServiceNames
}
