<#
.SYNOPSIS
    Installs Sitecore packages as listed in the package file location (json format)
.DESCRIPTION
    Script that calls the Sitecore package installation service to install Sitecore packages as listed in a file
.PARAMETER packagesFileLocation
    The Path to the file containing the Sitecore package list. This file has to be in JSON format and have following format:
    "packageInstallationServiceUrl" : "https://host/service",
    "serviceSharedSecret" : "xxxxx",
    "packages": [
    {
        "packageName" :"package1",
        "location": "url"
    },
    {
        "packageName": "package2",
        "location": "path"
    }


.EXAMPLE
    C:\PS> install-packages.ps1 -packagesFileLocation C:\my-project\solution-sitecore-packages.json
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$packagesFileLocation)
    
. $PSScriptRoot\sitecore-package-installer.ps1
$ErrorActionPreference = "Stop"

if((Test-Path -Path $packagesFileLocation) -eq $false)
{
    Write-Error -Message "solution-sitecore-packages.json not found at $packagesFileLocation"
    exit 1
}


$packages = (Get-Content $packagesFileLocation -Raw) | ConvertFrom-Json

[string]$sharedKey = ""; 


if ($packages.serviceSharedSecret -ne $null -and $packages.serviceSharedSecret -ne "") {    
    $sharedKey = $packages.serviceSharedSecret
}
else
{
    Write-Error "Shared Secret key is missing or empty"
    exit 1
}

if ($packages.packageInstallationServiceUrl -eq $null -or $packages.packageInstallationServiceUrl -eq "")
{
    Write-Error "packageInstallationServiceUrl is null or empty"
    exit 1
}

foreach ($package in $packages.packages) {
    if ( $package -ne $null)
    { Install-SitecorePackage -package $package -sharedSecret $sharedKey -serviceUrl $packages.packageInstallationServiceUrl }
}
