function Show-SqlFileInfo
{
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory = $true,
               Position = 1)]
    $sqlFileInfo
  )
  $sqlFileInfo | Out-String | Out-Host 
}