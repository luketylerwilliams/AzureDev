# This script runs in the default context of the SP

[CmdletBinding()]
param (
    [Parameter()]
    [boolean]
    $whatIf = $true # Default is true. Edit this to true/false if you want the action to take effect
)

$resourceIdArray = @()
$resourcesWithDiagArray = @()
$count = 0
$ErrorActionPreference = "silentlyContinue"

$resourceIdArray  = Get-AzResource | Select-Object -ExpandProperty ResourceId

Write-Output "Resource count with Diagnostics.."

foreach ($res in $resourceIdArray) {
    try {
        $output = Get-AzDiagnosticSetting -ResourceId $res -Name "service" -WarningAction SilentlyContinue
        $resourcesWithDiagArray+= $res
        $count += 1
        Write-Output $count
    }
    catch {
        "No Diagnostic settings"
    }
}

try {
    foreach ($res in $resourcesWithDiagArray) {
        if ($whatIf -eq $true) {
            $output = Remove-AzDiagnosticSetting -ResourceId $res -Name "service" -WhatIf -WarningAction SilentlyContinue
        }
        else {
            $output = Remove-AzDiagnosticSetting -ResourceId $res -Name "service" -WarningAction SilentlyContinuev
        }
    }
}
catch {
    Write-Output "Error when removing"
}

Write-output "Completed removing all"