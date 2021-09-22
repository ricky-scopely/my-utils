This is a simple tool that given a version and environment, prints the AppCenter download links from the latest version of the apps uploaded in AppCenter

![gif with an example](get-latest-release-script.gif)

# How To use
Invoke the script with the `ruby` command:
e.g:
`ruby get-latest-release-appcenter.rb --help`
Will print: 
```
Usage: --help [options]
	-v, --version VERSION            Application version to fetch
	-e, --environment ENV            Environment app to fetch
 	--print-json                 Prints json string fetched from app center to console containing all metadata from latest release
```

# Prerequisites:
[App center cli tool](https://github.com/microsoft/appcenter-cli) must be installed and available on your path

# Caveats
This was only tested on MacOS
