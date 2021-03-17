<#
.Synopsis
A scipt for finding all of the subscriptions with a given management group scope
.DESCRIPTION
For such a seemingly simple objective there is currently no easy way to list/retrieve all of the subscriptions under a given management group. 
This script also aims to include nested subscriptions which are within management groups beneath the given scope.
.Notes
Version   : 1.0
Author    : Luke Tyler Williams
Twitter   : @LT_Williams
Disclaimer: Please use this script at your own discretion, the author is not responsible for any result
.PARAMETER scope
Specify the management group scope to which you are trying to select
#>
param (
    # height of largest column without top bar
    [Parameter()]
    [string]$scope
)

$WarningPreference = "Ignore"
$mgScope = Get-AzManagementGroup -GroupId $script:scope -Expand -Recurse

$depth = 0
$scopeChildArray = @()

function hasChildren() {
    try {
        $getChildren = getScope | Select-Object -ExpandProperty Children
        if ($getChildren.count -ne 0) {
            Write-Host "Scope has children"
            $global:scopeChildArray = $getChildren
        }
        else {
            Write-Host "Provided Scope does not have any children"
        }
    }
    catch {
        Write-Host "Provided Scope does not have any children"
        break
    }
}

function getScope() {
    try {
        Get-AzManagementGroup -GroupId $script:scope -Expand -Recurse
        Write-Host "Scope is valid" -ForegroundColor Green
    }
    catch {
        Write-Host "Provided Scope is invalid"
        break
    }
}

function childrenHaveChildren() {
    foreach ($child in $scopeChildArray) {
        Get-AzManagementGroup -GroupId $child -Expand -Recurse
    }
    $getChildren = getScope | Select-Object -ExpandProperty Children
}

function Main() {
    getScope
    hasChildren
    #childrenHaveChildren
}

. Main