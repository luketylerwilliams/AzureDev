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
    [string]$scope,

    [Parameter()]
    [ValidateSet(
        "List",
        "Remove"
    )]
    [string]
    $runType = "List" # Default run type is list. If remove is specified then it will take that effect
)

$mgScope = Get-AzManagementGroup -GroupId Global -Expand -Recurse

$depth = 0
$getChildren = @()
$hasChildren = 0
try { 
    $getChildren = $mgScope | Select -ExpandProperty Children
    if ($getChildren.count -ne 0) {
        
    }
    $hasChildren = 1
}
catch {
    Write-Host "No children"
    $hasChildren = 0
}

if ($hasChildren -eq 0) {
    try {

    }
    catch {

    }
} 

function Main() {

}

. Main

function hasChildren() {
    try {

    }
    catch {
        Write-Host "Provided Scope does not have any children"
    }
}

function getScope() {
    try {

    }
    catch {
        Write-Host "Provided Scope does not have any children"
    }
}


