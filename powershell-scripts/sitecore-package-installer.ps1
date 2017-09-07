function GrantAccessToEveryoneForFile (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$file)
{
    Write-Verbose "Allowing access to everyone for $file"
    $Acl = Get-ACL $file

    # Get 'everyone' user on local language
    $auth = New-Object System.Security.Principal.SecurityIdentifier("S-1-1-0")
    $name = $auth.Translate([System.Security.Principal.NTAccount])

    $AllowEveryone= New-Object System.Security.AccessControl.FileSystemAccessRule($name.Value,"read","none","none","Allow")
    $Acl.AddAccessRule($AllowEveryone)
    Set-Acl $file $Acl
}

function Ignore-SSLCertificates
{
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider
    $Compiler = $Provider.CreateCompiler()
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters
    $Params.GenerateExecutable = $false
    $Params.GenerateInMemory = $true
    $Params.IncludeDebugInformation = $false
    $Params.ReferencedAssemblies.Add("System.DLL") > $null
    $TASource=@'
        namespace Local.ToolkitExtensions.Net.CertificatePolicy
        {
            public class TrustAll : System.Net.ICertificatePolicy
            {
                public bool CheckValidationResult(System.Net.ServicePoint sp,System.Security.Cryptography.X509Certificates.X509Certificate cert, System.Net.WebRequest req, int problem)
                {
                    return true;
                }
            }
        }
'@ 
    $TAResults=$Provider.CompileAssemblyFromSource($Params,$TASource)
    $TAAssembly=$TAResults.CompiledAssembly
    ## We create an instance of TrustAll and attach it to the ServicePointManager
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll")
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll
}

function Install-SitecorePackage (
    [Parameter(Mandatory=$true)]
    [object]$package,
    [Parameter(Mandatory=$true)]
    [string]$sharedSecret = [string]::Empty,
    [Parameter(Mandatory=$true)]
    [string]$serviceUrl = [string]::Empty,
    [System.Management.Automation.CredentialAttribute()]$credentials = $null
    ) 
{
    Write-Host "Getting" $package.packageName "Package"
    if ( $credentials -ne $null )
    {
        Write-Host "With credentials for user: " $credentials.UserName
    }  
       

    $packageLocation = $package.location
    if(-not (Test-Path $package.location))
    {
        Write-Host ("Package not found locally trying to download from " + $package.location)
            

        Import-Module BitsTransfer
        Start-BitsTransfer -Source $package.location -Destination ("{0}\{1}.zip" -f $env:temp, $package.packageName) -Credential $credentials -Authentication Basic

        if ( Test-Path ("{0}\{1}.zip" -f $env:temp, $package.packageName))
        {
            Write-Verbose "Sucessfully downloaded"
        }
        else
        {
            Write-Error "Something went wrong trying to download"
        }
        $packageLocation = ("{0}\{1}.zip" -f $env:temp, $package.packageName)

      
    }

    # Give read access to everyone to the file, needed so that the IIS process sure can access it. The service usually checks this as well, so
    # even if we didn't do it it wouln't work anyway. 
    GrantAccessToEveryoneForFile -file $packageLocation

    Write-Host "Installing" $package.packageName "from" $packageLocation "via service at" $serviceUrl "with sharedKey" $sharedSecret
    try {
        if ( $serviceUrl.Contains("localhost"))
        {
            Write-Verbose "Ignore SSL certificates for localhost service"
            Ignore-SSLCertificates
        }  
        
        $bodyParams = ("SharedKey={0}&Path={1}" -f $sharedSecret,$packageLocation)
        Write-Debug "Doing call with parameters: $bodyParams"
        wget $serviceUrl -Method POST -Body $bodyParams -TimeoutSec 1200
    }
    catch
    {
        Write-Host "Couldn't install package. Error message from wget: " $_.ErrorDetails " exception: " $_.Exception       
    }       

    Write-Host "Finished install call"
}