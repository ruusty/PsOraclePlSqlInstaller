function Set-SdlcConnections
<#
  .SYNOPSIS
    Returns a hashtable of Oracle connections given a SDLC name

  .DESCRIPTION
    Returns a hashtable of Oracle connections given a SDLC name

  .PARAMETER sdlc_environment
    The System Environment name


  .EXAMPLE
    		PS C:\> Set-SDLC_Connection -sdlc DEV

  .NOTES
    Additional information about the function.
#>
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $false,
               Position = 1)]
    [ValidateSet('DEV', 'TEST', 'UAT', 'PROD','UNKNOWN')]
    [string]$sdlc ='UNKNOWN'
  )
  switch -case ($sdlc.ToUpper())
  {
    DEV  {
            $netServiceNames = @{ pon = "POND.world"; onc = "ONCD.world"; sweg = "SWEG43D.world"; srr = "SRRD.world" }; break
    }
    TEST {
      $netServiceNames = @{ pon = "PONT.world"; onc = "ONCT.world"; sweg = "SWEG43U.world" }; break
    }
    UAT  {
            $netServiceNames = @{ pon = "PONU.world"; onc = "ONCU.world"; sweg = "SWEG43U.world"; cnc = "lvmu.world"; srr = "SRRU.world" }; break
    }
    PROD {
            $netServiceNames = @{ pon = "PONP.world"; onc = "ONCP.world"; sweg = "SWEG43P.world"; cnc = "lvmp.world"; srr = "SRRP.world" }; break
    }
    UNKNOWN {
            $netServiceNames = @{ pon = "PONX.world"; onc = "ONCX.world"; sweg = "SWEG43X.world"; cnc = "lvmx.world"; srr = "SRRX.world" }; break
    }
    default { throw "Unknown environment"; break }
  }
  $netServiceNames.GetEnumerator() | Sort-Object Name | % {
    write-verbose("$netServiceNames {0} : {1} " -f $_.name, $_.value)
  }
  $netServiceNames
}
