# cache

Database-less dependency management.

# Summary

Cache is a shell script that handles file dependencies from the command-line.


# Usage

A quick guide to the command line options is listed below: 
## Database stuff:
-	-e, --exists [arg]           
Does this file exist? 
-	-c, --create [arg]           
Add a package. 
-	    --mkdir [arg]            Make additional directories. 
-	    --touch [arg]            Create additional files.
-	-r, --remove [arg]           Remove a package. 
-u, --update [arg]           Update a package. 
-m, --commit [arg]           Commit changes to a package.
    --master [arg]           Update the master branch. 
-n, --needs [arg]            Set a dependence. 
-x, --no-longer-needs [arg]  Unset a dependency. 
    --list-needs [arg]       List <arg>'s dependencies.
    --ignore-needs           Disregard dependencies. 
-k, --link-to [arg]          Put a package somewhere.
    --symlink-to [arg]       Put a package somewhere.
    --link-ignore [arg]      Ignore these when linking out.
    --git-ignore [arg]       Ignore these when committing.
    --uninit [arg]           Remove all tracking information from git.
-b, --blob [arg]             Select by name. 
-u, --uuid [arg]             Select by unique identifier. 

## Parameter tuning:
    --version [arg]          Select or choose version. 
-s, --summary [arg]          Select or choose summary. 
    --produced-on [arg]      Select a date.
-a, --authors [arg]          Select or choose a set of authors. 
-q, --extra [arg]            Supply key value pairs of whatever else 
	                          should be tracked in a package. 

## General:
<code>
    --set-cache-dir [arg]    Set the cache directory to <arg>
-i, --info [pkg]             Display all information about a package.
	 --list-versions [arg]    List all the versions out.
    --contents [pkg]         Display all contents of a package.
-l, --list                   List all packages.
-d, --directory              Where is an application's home directory? 
    --dist-info              Display information about how \`$PROGRAM\` is setup
    --install [arg]          Install this to a certain location. 
    --uninstall              Uninstall this. 
-v, --verbose                Be verbose in output.
-h, --help                   Show this help and quit.
</code>

## Under construction:
    --required [arg]         Define parameters required when creating a package.
    --cd [arg]               Use <arg> as the current cache directory.
	                          (Will fail if .CACHE_DB is not there.)
