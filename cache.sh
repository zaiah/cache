#!/bin/bash -
#-----------------------------------------------------#
# cache
#
# A database-less way to manage dependencies.
#-----------------------------------------------------#
#-----------------------------------------------------#
# Licensing
# ---------
# Copyright (c) <year> <copyright holders>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-----------------------------------------------------#
PROGRAM="cache"


# References to $SELF
BINDIR="$(dirname "$(readlink -f $0)")"
SELF="$(readlink -f $0)"
source $BINDIR/lib/__.sh


# Fetch a random number out of nowhere.
rand() { random -l 40 | sed 's#/#_#g' | sed 's#=#+#g'; }

# Get ID of a name that's already there.
get_id() {
	printf ''
}

# exists?
exists() {
	[ ! -z "$1" ] && {
		[ -f "$CACHE_DB" ] && {
			# cut -f 2 -d '|' $CACHE_DB | sed -n "/^$BLOB$/p"
			[ ! -z "`cut -f 2 -d '|' $CACHE_DB | sed -n "/^$1$/p"`" ] && {
				error -p "$PROGRAM" -e 1 -m "Application '$1' already exists."
			}
		}
	}
}

not_exists() {
	[ ! -z "$1" ] && {
		[ -f "$CACHE_DB" ] && {
			# cut -f 2 -d '|' $CACHE_DB | sed -n "/^$BLOB$/p"
			[ -z "`cut -f 2 -d '|' $CACHE_DB | sed -n "/^$1$/p"`" ] && {
				error -p "$PROGRAM" -e 1 -m "Application '$1' does not exist."
			}
		}
	}
}


SVAR=
save_args() {
	SVAR="$SVAR\n$1"	
}


# Must eat the arguments and spit back out...
optexpander() {
	printf '' > /dev/null
}


# usage - Show usage message and die with $STATUS
usage() {
   STATUS="${1:-0}"
   echo "Usage: ./$PROGRAM
	[ -  ]
Database stuff:
-e, --exists <arg>           Does this file exist? 
-c, --create <arg>           Add a package. 
-r, --remove <arg>           Remove a package. 
-u, --update <arg>           Update a package. 
-n, --needs <arg>            Set a dependence. 
-x, --no-longer-needs <arg>  Unset a dependency. 
--, --needs <arg>            Set a dependence. 
--, --needs <arg>            Set a dependence. 
    --load-needs <arg>      Load dependencies from a file. (Use --load-needs -help for more.) 

Package tuning:
-q, --required <arg>         Which parameters are required when creating a package? 
-v, --version <arg>          Select or choose version. 
-u, --uuid <arg>             Select by UUID. 
-s, --summary <arg>          Select or choose summary. 
    --description <arg>      Select or choose description. 
-t, --title <arg>            Select or choose title. 
-n, --namespace <arg>        Select or choose name. 
-f, --filename <arg>         Select by filename. 
-u, --url <arg>              Select or choose by URL 
    --produced-on <arg>      Select a date.
-a, --authors <arg>          Select or choose a set of authors. 
    --signature <arg>        Select or choose a signature. 
    --key <arg>              Select or choose a key. 
    --fingerprint <arg>      Select or choose a fingerprint.
    --extra <arg>            

General:
-i, --interpret              Interpret the manifest file for a package.
-l, --list                   List all packages.
    --file                   Where is the default file? 
    --folder                 Where is the default folder? 
    --default                What is the default (?)?
    --info                   Show me additional information.
    --install <arg>          Install this to a certain location. 
    --uninstall              Uninstall this. 
-v, --verbose                Be verbose in output.
-h, --help                   Show this help and quit.
"
   exit $STATUS
}


# Die if no arguments received.
[ -z "$BASH_ARGV" ] && printf "Nothing to do\n" > /dev/stderr && usage 1


# Need an array. (or big string)

# Process options.
while [ $# -gt 0 ]
do
   case "$1" in
     -e|--exists)
         DO_EXISTS=true
         shift
         EXISTS="$1"
      ;;
     -r|--required)
         DO_REQUIRED=true
         shift
         REQUIRED="$1"
      ;;
	  -b|--blob)
		   shift
			BLOB="$1"
		;;
     -c|--create)
         DO_CREATE=true
         shift
         BLOB="$1"
      ;;
     -r|--remove)
         DO_REMOVE=true
         shift
         BLOB="$1"
      ;;
     -u|--update)
         DO_UPDATE=true
         shift
         BLOB="$1"
      ;;
     -n|--needs)
         DO_NEEDS=true
         shift
         NEEDS="$1"
      ;;
     -n|--no-longer-needs)
         DO_NO_LONGER_NEEDS=true
         shift
         NO_LONGER_NEEDS="$1"
      ;;
     --load-needs)
         DO_LOAD_NEEDS=true
         shift
         LOAD_NEEDS="$1"
      ;;
     -s|--summary)
         DO_SUMMARY=true
         shift
         SUMMARY="$1"
      ;;
     -v|--version)
         DO_VERSION=true
         shift
         save_args "VERSION=$1"
      ;;
     -u|--uuid)
         DO_UUID=true
         shift
         UUID="$1"
      ;;
     -d|--description)
         DO_DESCRIPTION=true
         shift
			save_args "DESCRIPTION=$1"
      ;;
     -t|--title)
         DO_TITLE=true
         shift
         save_args "TITLE=$1"
      ;;
     -n|--namespace)
         DO_NAMESPACE=true
         shift
         save_args "NAMESPACE=$1"
      ;;
     -f|--filename)
         DO_FILENAME=true
         shift
         save_args "FILENAME=$1"
      ;;
     -u|--url)
         DO_URL=true
         shift
         save_args "URL=$1"
      ;;
     --produced-on)
         DO_PRODUCED_ON=true
         shift
         save_args "PRODUCED_ON=$1"
      ;;
     --authors)
         DO_AUTHORS=true
         shift
         save_args "AUTHORS=$1"
      ;;
     --primary-author)
         DO_AUTHORS=true
         shift
         save_args "PRIMARY_AUTHOR=$1"
      ;;
     --signature)
         DO_SIGNATURE=true
         shift
         save_args "SIGNATURE=$1"
      ;;
     --key)
         DO_KEY=true
         shift
         save_args "KEY=$1"
      ;;
     --fingerprint)
         DO_FINGERPRINT=true
         shift
         save_args "FINGERPRINT=$1"
      ;;
     --extra)
         DO_EXTRA=true
         shift
         EXTRA="$1"
      ;;
     --install)
         DO_INSTALL=true
         shift
         INSTALL_DIR="$1"
      ;;
     --uninstall)
         DO_UNINSTALL=true
      ;;
     --file)
         DO_FILE=true
      ;;
     --folder)
         DO_FOLDER=true
      ;;
     --default)
         DO_DEFAULT=true
      ;;
     -i|--interpret)
        DO_INTERPRET=true
		  shift
		  BLOB="$1"
      ;;
     -l|--list)
        DO_LIST=true
      ;;
     -v|--verbose)
        VERBOSE=true
      ;;
     -h|--help)
        usage 0
      ;;
	  --echo)
		  
		;;
	  --reset)
		  	source $BINDIR/.CACHE
			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
		;;
	  --total-reset)
		  	source $BINDIR/.CACHE
			init --uninstall
			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
		;;
     --) break;;
     -*)
      printf "Unknown argument received: $1\n" > /dev/stderr;
      usage 1
     ;;
     *) break;;
   esac
shift
done


# Install...
# install
[ ! -z $DO_INSTALL ] && {
	# Check for missing stuff.
  	init --fatal-if-missing "git,sed,awk,mkdir" 

	# Populate the $CONFIG file.
	init --write "CONFIG=$HOME/.cache"

	# Install the files.
	init -i "cache.sh" --install-to "$INSTALL_DIR"
}


# uninstall
[ ! -z $DO_UNINSTALL ] && {
 	init --uninstall
}


# Generate a .CACHE file.
CACHE_CONFIG="$BINDIR/.CACHE"
if [ ! -f "$CACHE_CONFIG" ]
then
	REMOTE_URL_ROOT=${REMOTE_URL_ROOT}
	REMOTE_GLOBAL_KEY=${REMOTE_GLOBAL_KEY}
	CACHE_DIR="${CACHE_DIR:-"$BINDIR/.${PROGRAM}/applications"}"

	echo "
CACHE_DIR="$CACHE_DIR"
CACHE_DB="\$CACHE_DIR/.CACHE_DB"
DEFAULT_VERSION=0.00
FORMAT=DATESTAMP	# UUID, NONE, and CUSTOM are other choices.
FORMAT_CUSTOM=
REMOTE_URL_ROOT=$REMOTE_URL_ROOT
REMOTE_GLOBAL_KEY=$REMOTE_GLOBAL_KEY" > $CACHE_CONFIG

fi


# Grab the CACHE_CONFIG
source $CACHE_CONFIG


# Basic information...
# file
[ ! -z $DO_FILE ] && {
   printf '' > /dev/null
}
# folder
[ ! -z $DO_FOLDER ] && {
   printf '' > /dev/null
}

# required
[ ! -z $DO_REQUIRED ] && {
   printf '' > /dev/null
}

# List 
[ ! -z $DO_LIST ] && {
	awk -F '|' '{
		print "App Name:      " $2
		print "App ID:        " $1
		print "App Location:  " $3
		print "\n"
	}' $CACHE_DB 
}


## Packages
# exists
[ ! -z $DO_EXISTS ] && {
	exists $BLOB
}

# create
[ ! -z $DO_CREATE ] && {
	# Title and summary are always required.
	[ -z "$SUMMARY" ] && {
		error -p "$PROGRAM" -e 1 -m "No summary specified."
	}

	# Check for the name first.
	exists $BLOB

	# Get some defaults.
	UUID=${UUID-`rand`}
	TITLE=${TITLE-$BLOB}

	# Handle folder names.
	case "$FORMAT" in 
		DATESTAMP) FORMAT="$(date +%F).$(date +%s)" ;;
		UUID) FORMAT="`rand | head -c 20`" ;;
		# CUSTOM) FORMAT="$(date +%F).$(date +%s)" ;;
	esac

	# Common vars.
	FOLDER="$CACHE_DIR/${BLOB}.${FORMAT}"
	DEPENDENCIES="$FOLDER/DEPENDENCIES"
	MANIFEST="$FOLDER/MANIFEST"

	# If the folder doesn't exist already, then create it.
	[ ! -d "$FOLDER" ] && mkdir -pv $FOLDER

	# Make a file for dependencies too, and authors, etc.
	[ ! -d "$DEPENDENCIES" ] && touch $DEPENDENCIES

	# Put this manifest somewhere.
	{
		echo " 
VERSION=$VERSION
UUID=$UUID
DESCRIPTION='$DESCRIPTION'
SUMMARY='$SUMMARY'
TITLE='$TITLE'
NAMESPACE=$NAMESPACE
FILENAME=$BLOB
URL=$URL
PRODUCED_ON=$PRODUCED_ON
AUTHORS=$AUTHORS
SIGNATURE=$SIGNATURE
KEY=$KEY
FINGERPRINT=$FINGERPRINT
"
	} > $MANIFEST

	# Does file exist in database?
	# If not, add a record to your file based database.
	{ 
		printf "$UUID|"
		printf "$TITLE|"
		printf "`basename $FOLDER`\n"
	} >> $CACHE_DB
}


# remove
[ ! -z $DO_REMOVE ] && {
	# Is it there?
	not_exists $BLOB

	# Find entry in the file based database.
	ENTRY=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g'`
	# printf "$ENTRY\n" | awk -F ':' '{ print $4 }'
	LINE=`printf "$ENTRY\n" | awk -F ':' '{ print $1 }'`
	FOLDER=`printf "$ENTRY\n" | awk -F ':' '{ print $4 }'`

	# Remove the folder
	[ -d "$FOLDER" ] && rm -rfv $FOLDER

	# Remove from the file based database.
 	sed -i ${LINE}d $CACHE_DB
}


# update
[ ! -z $DO_UPDATE ] && {
	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Define the manifest
	MANIFEST="$CACHE_DIR/$FOLDER/MANIFEST"

	# Load them all variables first. 
	tmp_file -n JELLY
	# printf "$SVAR" > $JELLY
	printf "$SVAR\n" > $JELLY
#	cat $JELLY
#	exit
	# Go over each.
	while read line 
	do
		# Get the matching thing.
		# sed -n "/^[A-Z].*=/p"
#		sed "s/^\([A-Z].*\)=.*/\1/" | {
		TERM=`printf "$line" | awk -F '=' '{ print $1 }'` 
		VALUE=`printf "$line" | awk -F '=' '{ print $2 }'` 
		if [ ! -z "`sed -n "/^${TERM}=/p" $MANIFEST`" ] 
		then
			# Run a permanent replacement with sed.
			sed -i "s/^\(${TERM}=\).*/\1\"${VALUE}\"/" $MANIFEST
			# sed "s/^\(${TERM}=\).*/\1\"${VALUE}\"/" $MANIFEST

		# Just append it otherwise.
		else
			# printf -- "%s\n" "${TERM}=\"${VALUE}\""  # >> $MANIFEST
			printf -- "%s\n" "${TERM}=\"${VALUE}\""  >> $MANIFEST
		fi
	done < $JELLY
}


# Interpret a MANIFEST document. 
[ ! -z $DO_INTERPRET ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Define the manifest
	MANIFEST="$CACHE_DIR/$FOLDER/MANIFEST"
   
	# Read things.
	while read line
	do
		[ ! -z "$line" ] && {
			printf "%s" "$line" | \
				awk -F '=' '{ print $1 }' | \
				tr '[A-Z]' '[a-z]' | \
				sed 's/_/ /' | \
				sed 's/^[a-z]/\u&/' | \
				sed 's/$/:/'

			printf "%s" "$line" | awk -F '=' '{ print $2 }' 
		}
	done < $MANIFEST
}


# Commit
[ ! -z $DO_COMMIT ] && {
   printf '' > /dev/null
}


# Set and manage dependencies.
# needs
[ ! -z $DO_NEEDS ] && {
	# Check that the file being asked to depend on exists.
	# One at a time for now.

	# Set the dependence from here.
   printf '' > /dev/null
}

# no_longer_needs
[ ! -z $DO_NO_LONGER_NEEDS ] && {
   printf '' > /dev/null

	# Remove from the file based database.
 	sed -i ${LINE}d $CACHE_DB
}

# load_needs (Load the dependencies from some file.)
[ ! -z $DO_LOAD_NEEDS ] && {
	# Show help.
	[[ $DEP_FILE == "-help" ]] && {
		echo "
		" > /dev/stdout
	}

	# Otherwise, load some files.
	[ -f "$DEP_FILE" ] && {
   	printf '' > /dev/null

	}
}

# list needs (list the dependencies for a file)
[ ! -z $DO_LIST_NEEDS ] && { printf '' > /dev/null; }

# assess needs (are all the dependencies on this system?)
[ ! -z $DO_ASSESS_NEEDS ] && { printf '' > /dev/null; }


## Parameters
# version
[ ! -z $VERSION ] && { printf '' > /dev/null; }

# description
[ ! -z "$DESCRIPTION" ] && { printf '' > /dev/null; }
[ ! -z "$SUMMARY" ] && { printf '' > /dev/null; }
[ ! -z $TITLE ] && { printf '' > /dev/null; }
[ ! -z $NAMESPACE ] && { printf '' > /dev/null; }
[ ! -z $FILENAME ] && { printf '' > /dev/null; }
[ ! -z $URL ] && { printf '' > /dev/null; }
[ ! -z $PRODUCED_ON ] && { printf '' > /dev/null; }
[ ! -z $AUTHORS ] && { printf '' > /dev/null; }
[ ! -z $SIGNATURE ] && { printf '' > /dev/null; }
[ ! -z $KEY ] && { printf '' > /dev/null; }
[ ! -z $FINGERPRINT ] && { printf '' > /dev/null; }
[ ! -z $EXTRA ] && { printf '' > /dev/null; }



