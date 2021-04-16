<#
.Synopsis
A script for finding all public storage containers
.DESCRIPTION
For such a seemingly simple objective there is currently no easy way to list/retrieve all of containers across a given scope which could be
publicly accessible and potentially exposing sensitive information.
.Notes
Version   : 1.0
Author    : Luke Tyler Williams
Twitter   : @LT_Williams
Disclaimer: Please use this script at your own discretion, the author is not responsible for any result
.PARAMETER scope
Specify the scope to which you are trying to target e.g. management group, subscription or resource group
#>
param (
    [Parameter()]
    [string]$scope,

    [Parameter()]
    [string]$scopeId,

    [Parameter()]
    [string]$usageOption
)

Write-Host '
Find all ' -ForegroundColor Yellow
Write-Host '
-------------------------------USAGE-------------------------------
    Parameters:
        > -Scope <INPUT> | Specify the scope object. Options: Management group, Subscription or Resource Group. 
            >> If resource group is chosen then the parent subcription id must be provided.
            >> For example, setting the scope to a management group: 
                >>> .\AzQuicklog.ps1 -Scope "Management group"

        > -ScopeId <INPUT> | Specify the name of the scope object (case insensitive)
            >> For example, setting the scope to a management group called "lukeroot": 
                >>> .\AzQuicklog.ps1 -Scope "Management group" -ScopeId "lukeroot"

' -ForegroundColor Cyan

if ($script:scope.ToLower() -eq "resource group" -or $script:scope -eq 3) {
    # User provided option 3 / resource group
    Write-Host "Scope specified:" $script:scope -ForegroundColor Green
    $global:rgParentSub = Read-Host "Enter the parent subscription id for the resource group"
}
elseif (!$script:scope) {
    # Prompt user for input if no scope provided
    Write-Host "Scope Options: [1] Management group, [2] Subscription or [3] Resource Group" -ForegroundColor Yellow
    $script:scope = Read-Host "Enter the Scope" 
    if ($script:scope -eq 3) {
        $global:rgParentSub = Read-Host "Enter the parent subscription id for the resource group"
    }
} 
else {
    # User either specified 1 or 2
    Write-Host "Scope specified:" $script:scope -ForegroundColor Green
}
if (!$script:scopeId) { 
    # Prompt user for input if no scope id provided
    Write-Host "ScopeId (the management group id, subscription id or resource group name), For example: Global-UK or UK-Prod" -ForegroundColor Yellow
    $script:scopeId = Read-Host "Enter the Scope Id"
} 
else {
    # User specified scopeid
    Write-Host "ScopeID specified:" $script:scopeId -ForegroundColor Green
}
if (!$script:usageOption) { 
    # Prompt user for input if no scope id provided
    Write-Host "Usage Options. For actions use: 1 - Generate and use SAS token, 2 - Privileged authenticated account)" -ForegroundColor Yellow
    $script:usageOption = Read-Host "Enter the Usage Option"
} 
else {
    # User specified scopeid
    Write-Host "Usage Options specified:" $script:scopeId -ForegroundColor Green
}


# Global variables for functions
$global:azResources = @()
$global:azSubs = @()
$global:rgParentSub = ""

## Global variables for subcription enumeration under a given management group
$WarningPreference = "Ignore"
$global:setScope = $script:scopeId
$global:scopeObject = @()
$global:scopeChildArray = @()
$global:returnScope = $script:scope
$global:subscriptionArray = @()
# Extra
$global:resourcesWithDiagSubscriptions = @()
$global:showSubMenu = 1
$global:resourcesWithDiag = @()
# Logic for reassessing after deletion
$global:deletionRan = 0

function ScopeSelection() {
    if ($script:scope.ToLower() -eq "management group" -or $script:scope -eq 1) {
        ResourcePopulateMultipleSubscriptions
    }
    elseif ($script:scope.ToLower() -eq "subscription" -or $script:scope -eq 2) {
        ResourcePopulateSingular
    }
    elseif ($script:scope.ToLower() -eq "resource group" -or $script:scope -eq 3) {
        ResourcePopulateSingular
    }
    else { 
        Write-Host "Invalid input please try again" -ForegroundColor Red
        break
    }
}



function TargetSelection() {
    $subscriptionName = Get-AzContext | Select-Object -ExpandProperty Subscription | Select-Object -ExpandProperty Name
    Write-Host "--------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Getting all storage accounts for "$subscriptionName -ForegroundColor Green
    $global:azResources += Get-AzStorageAccount
    
}

function ResourcePopulateSingular() {
    if ($script:scope.ToLower() -eq "subscription" -or $script:scope -eq 2) {
        # Set the context to the subscription scope provided
        Set-AzContext -SubscriptionId $script:scopeId
        TargetSelection
        # Function completion, reshow menu
        subMenu
    }
    elseif ($script:scope.ToLower() -eq "resource group" -or $script:scope -eq 3) {
        # Get resource group subscription context
        $getRGSub = Get-AzResourceGroup -Name $script:scopeId | Select-Object -ExpandProperty ResourceId
        $rgSubId = ($getRGSub -split "/")[2]
        # Set the context to the subscription which the resource group is located in
        Set-AzContext -SubscriptionId $rgSubId
        TargetSelection
        # Function completion, reshow menu
        subMenu
    }
}

function ResourcePopulateMultipleSubscriptions() {
    # Get all Azure Subscriptions
    Write-Host "--------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Enumerating through management groups and subscriptions" -ForegroundColor Yellow
    getScope
    # Iterate through array and check if the subscription is valid
    foreach ($sub in $global:scopeChildArray) {
        try {
            $testSub = Get-AzSubscription -SubscriptionId $sub -ErrorAction Stop
            $global:subscriptionArray += $sub
        }
        catch [System.Management.Automation.PSArgumentException] {
            continue
        } 
        catch { 
            continue
        }
    }
    # Loop through all Azure Subscriptions and get the resources
    Write-Host "--------------------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Beginning loop through subscriptions to get all resources" -ForegroundColor Yellow

    foreach ($azSub in $global:subscriptionArray) {
        try {
            Write-Host "Setting context to Subscription:" $azSub
            Set-AzContext -Subscription $azSub -ErrorAction Stop | Out-Null
            TargetSelection
        }
        catch { 
            continue
        }  
    } 
    # Function completion, reshow menu
    subMenu
}

function hasChildren() {
    try {
        $getChildren = $global:scopeObject | Select-Object -ExpandProperty Children
        $getScopeId = $global:scopeObject | Select-Object -ExpandProperty Name
        $global:scopeChildArray += $getScopeId
        if ($getChildren.count -ne 0) {
            Write-Host "Scope has children"
            foreach ($child in $getChildren) {
                $global:scopeChildArray += $child.Name   
                $global:setScope = $child.Name
                getScope
            }  
        }
        else {
            Write-Host "Provided Scope does not have any children"
        }
    }
    catch {
        Write-Host "Problem with finding child objects"
    }
}

function getScope() {
    try {
        $global:scopeObject = Get-AzManagementGroup -GroupId $global:setScope -Expand -Recurse -ErrorAction Ignore
        hasChildren
    }
    catch {
        Write-Host "Problem with scope"
    }
}

function printResources() {
    if ($global:azResources) {
        $global:azResources | Format-Table
    }
    else {
        Write-Host "No resources captured with given parameters`n" -ForegroundColor Red
    }
    # Function completion, reshow menu
    subMenu
}

function findBlob() {
    if ($script:scope.ToLower() -eq "management group" -or $script:scope -eq 1) {
        foreach ($sub in $global:subscriptionArray) {

        }
    }
    elseif ($script:scope.ToLower() -eq "subscription" -or $script:scope -eq 2) {
        Set-AzContext -Subscription $script:scope
        foreach ($sub in $global:subscriptionArray) {
            foreach ($resource in $global:azResources) {
                if ($script:usageOption -eq 1) {
                    $SasToken = New-AzStorageContainerSASToken -Name "ContosoMain" -Permission "rad"
                    $Context = New-AzStorageContext -StorageAccountName "ContosoGeneral" -SasToken $SasToken
                    $Context | Get-AzStorageBlob -Container "ContosoMain"
                } 
                elseif ($script:usageOption -eq 2) {
                    New-AzStorageContext -StorageAccountName "myaccountname" -UseConnectedAccount
                }
                else { 
                    Write-Host "Usage option not set"
                }
            }
        }
    }
    elseif ($script:scope.ToLower() -eq "resource group" -or $script:scope -eq 3) {
        Set-AzContext -Subscription $global:rgParentSub
        foreach ($sub in $global:subscriptionArray) {
            foreach ($resource in $global:azResources) {
                if ($script:usageOption -eq 1) {
                    $SasToken = New-AzStorageContainerSASToken -Name "ContosoMain" -Permission "rad"
                    $Context = New-AzStorageContext -StorageAccountName "ContosoGeneral" -SasToken $SasToken
                    $Context | Get-AzStorageBlob -Container "ContosoMain"
                } 
                elseif ($script:usageOption -eq 2) {
                    New-AzStorageContext -StorageAccountName "myaccountname" -UseConnectedAccount
                }
                else { 
                    Write-Host "Usage option not set"
                }
            }
        }
    }
}

function findContainer() {

}

function findBlobContainer() {

}

function subMenu() {
    Write-Host "============= MENU ==============" -ForegroundColor Yellow
    Write-Host 'Choose from the following:
1: Print resources found in specified scope
2: Find all containers with blob access level(anonymous read)
3: Find all containers with container access level (anonymous read access for containers and blobs)
4: Find all containers with blob and container access level
5: Set option to: Use SAS
6: Set option to: Use privileged account
Q: Press "Q" to quit' -ForegroundColor Cyan
    $selection = Read-Host "Please make a selection"
    switch ($selection) {
        '1' {
            printResources
        } '2' {
            setStorageContext
        } '3' {
            setStorageContext
        } '4' {
            setStorageContext
        } '5' {
            $global:usageOption = 1
        } '6' {
            $global:usageOption = 2
        } 'Q' {
            'You chose to quit'
            return
        }
    }
}

function Main() {
    # Login with Connect-AzAccount if you're not using Cloud Shell
    try {
        Connect-AzAccount -ErrorAction Stop | Out-Null
    }
    catch {
        # Break if user authentication cancelled
        Write-Host "User authentication cancelled, script stopping" -ForegroundColor Red
        break
    }
    ScopeSelection
}

. Main