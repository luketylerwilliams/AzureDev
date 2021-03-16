# This script runs in the default context of the SP

$resourceIdArray = @()
$resourcesWithDiagArray = @()
$count = 0
$ErrorActionPreference = "silentlyContinue"

$resourceIdArray  = Get-AzResource | Select-Object -ExpandProperty ResourceId

Write-Output "Resource count with Diagnostics.."

foreach ($res in $resourceIdArray) {
    try {
        $output = Get-AzDiagnosticSetting -ResourceId $res -Name 'service' -WarningAction SilentlyContinue
        $resourcesWithDiagArray+= $res
        $count += 1
        Write-Output $count 
    }
    catch {
        "No Diagnostic settings"
    }
}

Write-output "Printing all resource ids for resources with diagnostic settings"
Write-output $resourcesWithDiagArray