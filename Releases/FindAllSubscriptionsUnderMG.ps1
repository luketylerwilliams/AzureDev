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
$global:setScope = $script:scope
$global:scopeObject = @()
$depth = 0
$global:scopeChildArray = @{}

function hasChildren() {
    try {
        $getChildren = $global:scopeObject | Select-Object -ExpandProperty Children
        $getScopeName = $global:scopeObject | Select-Object -ExpandProperty Name
        $global:scopeChildArray.$getScopeName = @()
        if ($getChildren.count -ne 0) {
            Write-Host "Scope has children"
            $getChildren
            foreach ($child in $getChildren) {
                $global:scopeChildArray.$getScopeName
                $global:scopeChildArray.$getScopeName += $child.Name

                $global:setScope = $child.Name
                getScope
                
            }
             
        }
        else {
            Write-Host "Provided Scope does not have any children"
        }
    }
    catch {
        Write-Host "Problem"
        break
    }
}

function getScope() {
    try {
        $global:scopeObject = Get-AzManagementGroup -GroupId $global:setScope -Expand -Recurse
        hasChildren
    }
    catch {
        Write-Host "problem"
    }
}

function testInitialScope() {
    try {
        Get-AzManagementGroup -GroupId $global:setScope -Expand -Recurse
        Write-Host "Scope is valid" -ForegroundColor Green
        getScope
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
    testInitialScope
    getScope
    #childrenHaveChildren
}

. Main