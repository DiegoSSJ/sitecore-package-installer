# Sitecore package installer npm gulp package

Provides gulp tasks for installation of Sitecore packages through Url service
It supports several versions of Sitecore and Solr and can work with both Solr standalone and SolrCloud. 



Based on the great installation instructions from the sitecore community documentation at
https://sitecore-community.github.io/docs/search/solr/fast-track-solr-for-lazy-developers/


## Usage

This npm package is intended to be included from a Sitecore Habitat project. It is included via package.json like this:

```
  "dependencies": {    
    "sitecore-package-installer": "^1.0.0"
  }
```

Then it gets installed with ```npm install```

It then provides a task called ```install-sitecore-packages``` that can be run from your solution's gulp file. It runs a task that parses the solution-sitecore-packages.json file and then
iterates over the list of packages to install.

You can include it in your project setup like this:
```
var buildtasks = require('./node_modules/sitecore-package-installer/gulpfile.js');
gulp.task("00-Setup-Development-Environment", function (callback) {
  runSequence(    
    "install-sitecore-packages")
	})
```

Or run it manually from gulp

```
gulp install-sitecore-packages
```


## Gulp task parameters

The gulp tasks expects a file named "solution-sitecore-packages.json" on the root of the solution folder (where gulp is executed) containing the following structure:
```
{
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
}
```

Where the "packageInstallationServiceUrl" is the path to the service that will run the installation for the Sitecore package
"serviceSharedSecret" is a secret key to be able to use abovementioned service
and "packages" is the list of Sitecore packages to install, each containing a "packageName" and a "location" that can either be an url to fetch from or a location on disk. 
The process will check if the "location" variable is in disk, if it is not it'll try to download it. 