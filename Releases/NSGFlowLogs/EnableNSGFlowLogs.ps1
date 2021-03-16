[CmdletBinding()]
param (
    # Run type parameters
    [Parameter()]
    [ValidateSet(
        "List",
        "Enable"
    )]
    [string]
    $runType = "List", # Default runType is list
    
    [Parameter()]
    [boolean]
    $whatIf = $true # Default is true. Edit this to true/false if you want the action to take effect
)

### DO NOT TOUCH - These values are populated by running the script ###
# This is set to the resource groups with all of the NSG's
$global:resourceGroupArray = @{}
$global:nsg = ""
$global:storageAccountRegion = ""
$global:storageAccountRG = ""
$global:networkWatcherName = ""
$global:networkWatcherRG = ""
##################################
########## EDIT THESE ############
$global:storageAccount = ""
$global:workspaceLocation = "" # Insert value here for Log Analytics Workspace Location
$global:workspaceGUID = "" # Insert value here for Log Analytics Workspace GUID
$global:workspaceResID = "" # Insert value here for Log Analytics Workspace GUID
##################################

function Main {
    switch -regex ($runType) {
        "List" { ResourceList; break }
        "Enable" { EnableNSGFlowLogs; break }
    }
}

function ResourceList {
    # Set context here if necessary (depends on SPN permissions and default context)
    Write-Output "`n Storage Account: " $global:storageAccount
    GetStorageAccountRegion
    Write-Output "`n Storage Account Location: " $global:storageAccountRegion
    Write-Output "`n ======================"
    GetNetworkWatcherRG
    Write-Output "`n Network Watcher: " $global:networkWatcherName
    Write-Output "`n Network Watcher Resource Group: " $global:networkWatcherRG
    Write-Output "`n ======================"
    Write-Output "`n NSG: " 
    GetAllNSGforRegion
    Write-Output "`n ======================"
    Write-Output "`n Resource Group: " 
    Write-Output $global:resourceGroupArray
}

function GetNetworkWatcherRG {
    $nwArray = @()
    $nwArray = Get-AzNetworkWatcher -Name NetworkWatcher*
    foreach ($nw in $nwArray) {
        if ($nw.Location -eq $global:storageAccountRegion) {
            $global:networkWatcherName = $nw.Name
            $global:networkWatcherRG = $nw.ResourceGroupName 
        }
    }
}

function GetStorageAccountRegion {
    $storageArray = @()
    $storageArray = Get-AzStorageAccount
    foreach ($storage in $storageArray) {
        if ($storage.StorageAccountName -eq $global:storageAccount) {
            $global:storageAccountRegion = $storage.Location
            $global:storageAccountRG = $storage.ResourceGroupName
        }
    }
}

function GetAllNSGforRegion {
    #Get resource group for region
    $rgArray = @()
    $rgArray = Get-AzResourceGroup -Location $global:storageAccountRegion | Select-Object -Property ResourceGroupName

    Write-Output "`nPrinting all RG's in the same region as Network Watcher"
    Write-Output $rgArray | ft -HideTableHeaders
    Write-Output "`nChecking NSG's in the same region as Network watcher.."

    foreach ($rg in $rgArray) {
        $count = 0
        #Get nsg in network watcher region
        $nsgArray = @()
        $nsgArray = Get-AzNetworkSecurityGroup -ResourceGroupName $rg.ResourceGroupName | Select-Object -Property Name, Location 

        foreach ($nsg in $nsgArray) {
            $count += 1
            Write-Output "Result: '$count'"
            if ($nsg.Location -eq $global:storageAccountRegion) {
                Write-Output "NSG matching region"
                Write-Output "Resource Group: $rg"
                Write-Output "Matching NSG: $nsg"
                #Store NSG name and RG
                $var1 = ($rg.ResourceGroupName | Out-String).trim()
                $var2 = ($nsg.Name | Out-String).trim()

                $global:resourceGroupArray.Add($var2, $var1)
            }
            else {
                Write-Output "Not matching region"
            }
        }
    }
}

function EnableNSGFlowLogs {

    ResourceList

    Write-Output "`n ======================"
    Write-Output "Running Enablement"


    if ($whatIf -eq $true) {
        $WhatIfPreference = $true
        $ConfirmPreference = "High"
    }
    else {
        $WhatIfPreference = $false
        $ConfirmPreference = "None"
    }


    $count = 0
    foreach ($rg in $global:resourceGroupArray.GetEnumerator()) {
        $count += 1
        Write-Output "Enabling: '$count'"

        $NW = Get-AzNetworkWatcher -ResourceGroupName $global:networkWatcherRG -Name $global:networkWatcherName
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $rg.Value -Name $rg.Key
        # Set context here if necessary
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $global:storageAccountRG -Name $global:storageAccount

        # Set context here if necessary
        Get-AzNetworkWatcherFlowLogStatus -NetworkWatcher $NW -TargetResourceId $nsg.Id

        #Configure Version 1 Flow Logs
        Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $nsg.Id -StorageAccountId $storageAccount.Id -EnableFlowLog $true -FormatType Json -FormatVersion 1

        #Configure Version 2 Flow Logs, and configure Traffic Analytics
        Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $nsg.Id -StorageAccountId $storageAccount.Id -EnableFlowLog $true -FormatType Json -FormatVersion 2

        #Configure Version 2 FLow Logs with Traffic Analytics Configured
        Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $nsg.Id -StorageAccountId $storageAccount.Id -EnableFlowLog $true -FormatType Json -FormatVersion 2 -EnableTrafficAnalytics -WorkspaceResourceId $global:workspaceResID -WorkspaceGUID $global:workspaceGUID -WorkspaceLocation $global:workspaceLocation

        #Query Flow Log Status
        Get-AzNetworkWatcherFlowLogStatus -NetworkWatcher $NW -TargetResourceId $nsg.Id

    }
}

. Main
