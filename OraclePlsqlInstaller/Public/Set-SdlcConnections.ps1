<#
  .SYNOPSIS
    Set the SDLC
  
  .DESCRIPTION
    set and verify the SDLC
  
  .PARAMETER sdlc_environment
    A description of the sdlc_environment parameter.
  
  .PARAMETER local_service
    A description of the local_service parameter.
  
  .EXAMPLE
    		PS C:\> Set-SDLC_Connection -sdlc_environment DEV 
  
  .NOTES
    Additional information about the function.
#>
function Set-SdlcConnections
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    [ValidateSet('DEV', 'TEST', 'UAT', 'PROD')]
    [string]$sdlc
  )
  
  switch -case ($sdlc)
  {
    DEV  {
      $local_services = @{ pon = "POND.world"; onc = "ONCD.world" }; break
    }
    TEST {
      $local_services = @{ pon = "PONT.world"; onc = "ONCT.world" }; break
    }
    UAT  {
      $local_services = @{ pon = "PONU.world"; onc = "ONCU.world"; sweg = "SWEG43U.world" }; break
    }
    PROD {
      $local_services = @{ pon = "PONP.world"; onc = "ONCP.world"; sweg = "SWEG43P.world" }; break
    }
    default { throw "Unknown environment"; break }
  }
  $local_services.GetEnumerator() | Sort-Object Name | % {
    write-verbose("$local_services {0} : {1} " -f $_.name, $_.value)
  }
  $local_services
}
