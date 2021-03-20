<#
.Synopsis
A script for finding all of the subscriptions and management groups with a given management group scope
.DESCRIPTION
For such a seemingly simple objective there is currently no easy way to list/retrieve all of the subscriptions and management groups
from a given management group scope. 
This script also includes nested subscriptions which are within management groups beneath the given scope.
.Notes
Version   : 1.0
Author    : Luke Tyler Williams
Twitter   : @LT_Williams
Disclaimer: Please use this script at your own discretion, the author is not responsible for any result
.PARAMETER scope
Specify the management group scope to which you are trying to target
#>
param (
    [Parameter()]
    [string]$scope
)

$WarningPreference = "Ignore"
$global:setScope = $script:scope
$global:scopeObject = @()
$global:scopeChildArray = @{}
$global:returnScope = $script:scope
$results = @()

function hasChildren() {
    try {
        $getChildren = $global:scopeObject | Select-Object -ExpandProperty Children
        $getScopeName = $global:scopeObject | Select-Object -ExpandProperty Name
        $global:scopeChildArray.$getScopeName = @()
        if ($getChildren.count -ne 0) {
            Write-Host "Scope has children"
            foreach ($child in $getChildren) {
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
    }
}

function getScope() {
    try {
        $global:scopeObject = Get-AzManagementGroup -GroupId $global:setScope -Expand -Recurse -ErrorAction Ignore
        hasChildren
    }
    catch {
        Write-Host "Problem"
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

function result() {
    drawHierarchy
}

function drawHierarchy() {
    Write-Host "============================================"
    Write-Host "================FINAL OUTPUT================"
    Write-Host "============================================"
    Write-Host "Scope: " $global:returnScope -ForegroundColor Yellow
    returnHierarchy
} 

function returnHierarchy() {
    $results = @()
    foreach ($val in $global:returnScope) {
        $results = $global:scopeChildArray.GetEnumerator() | Where-Object { $_.Key -eq $global:returnScope } | Select-Object -ExpandProperty Value
        foreach ($result in $results) {
            Write-Host $global:returnScope "|||" $result
        }
    }
    foreach ($result in $results) {
        $global:returnScope = $result
        returnHierarchy
    }
}

function Main() {
    Connect-AzAccount
    testInitialScope
    getScope
    result
}

. Main