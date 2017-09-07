/*jslint node: true */
"use strict";

var gulp = require("gulp");
var nopt = require("nopt");
var path = require("path");
var requireDir = require("require-dir");
var build = require("./build.js");
var powershell = require("./modules/powershell");
var fs = require("fs");

var args = nopt({
  "env"     : [String, null]
});

build.setEnvironment(args.env);

build.setEnvironment(args.env);
  
gulp.task("install-sitecore-packages", function (callback) {
  build.logEvent("builder", "Installing Sitecore packages");
  var psFile = path.join(path.dirname(fs.realpathSync(__filename)), "/powershell-scripts/Install-packages.ps1");
  var packagesConfig = path.join(process.cwd(), "/solution-sitecore-packages.json");
  var sitecoreRoleInstance = "cm"
  
  powershell.runAsync(psFile, " -packagesFileLocation '" + packagesConfig + "' -sitecoreInstanceRole '" + sitecoreInstanceRole + "'", callback);
});

gulp.task("default", function () {
	console.log("You need to specify a task.");
});

