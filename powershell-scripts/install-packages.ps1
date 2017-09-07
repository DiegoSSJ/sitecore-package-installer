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
    {
        "packageName": "package abc",
        "location": "http://site/package",
        "user" : "user",
        "password": "jjjjlll",
        "role": "cm"
    }
.PARAMETER sitecoreInstanceRole
    Optional parameter limiting the packages being installed from the list to the ones that only have the right role (see file format above). Ex "cm", "cd"
    If this parameter is missing it will install all packages not having an specific role. If the role is missing on a package, it will also install it irregardless
    of this parameter. 
    


.EXAMPLE
    C:\PS> install-packages.ps1 -packagesFileLocation C:\my-project\solution-sitecore-packages.json
.NOTES
    Author: Diego Saavedra San Juan
    Date:   Many
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$packagesFileLocation,
    [string]$sitecoreInstanceRole="cm")

$sitecoreInstanceRole = $sitecoreInstanceRole.ToLower();

if ( $sitecoreInstanceRole -eq "web" ) # Octopus uses web for role, so we manually change that to cd as in Sitecore naming
{
    $sitecoreInstanceRole = "cd"
}

    
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

Write-Host "Starting package installation for packages, instance role is" $sitecoreInstanceRole

foreach ($package in $packages.packages) {
    Write-Host "Checking package" $package.packageName
    if ( $package -ne $null )
    { 
        if ( $sitecoreInstanceRole -ne $null -and $sitecoreInstanceRole -ne "" -and
        $package.role -ne $null -and $package.role -ne "" -and $package.role.toLower() -ne $sitecoreInstanceRole)
        {
            Write-Host "Skipping package " $package.packageName "because instance role" $sitecoreInstanceRole "was specified, and the package has role" $package.role
            continue;
        }        

        if ( ($sitecoreInstanceRole -eq $null -or $sitecoreInstanceRole -eq "") -and
        $package.role -ne $null -and $package.role -ne "")
        {
            Write-Host "Skipping package " $package.packageName "because the package has a role ("$package.role") and no instance role was specified"
            continue;
        }

        $credentials = $null
        if ( $package.user -ne $null -and $package.user -ne "")
        {
            $securepassword = ConvertTo-SecureString $package.password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($package.user, $securepassword)
        }
        Install-SitecorePackage -package $package -sharedSecret $sharedKey -serviceUrl $packages.packageInstallationServiceUrl -credentials $credentials
    }
}
