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

# usage - Show usage message and die with $STATUS
usage() {
   STATUS="${1:-0}"
   echo "Usage: ./$PROGRAM
	[ -  ]
Database stuff:
-e | --exists <arg>           Does this file exist? 
-c | --create <arg>           Add a package. 
-r | --remove <arg>           Remove a package. 
-u | --update <arg>           Update a package. 
-n | --needs <arg>            Set a dependence. 
-n | --no-longer-needs <arg>  Unset a dependency. 
	  --load-needs <arg>       Load dependencies from a list. (Use --load-needs -help for more.) 

Package tuning:
-q | --required <arg>         Which parameters are required when creating a package? 
-v | --version <arg>          Select or choose version. 
-u | --uuid <arg>             Select by UUID. 
-s | --summary <arg>          Select or choose summary. 
     --description <arg>      Select or choose description. 
-t | --title <arg>            Select or choose title. 
-n | --namespace <arg>        Select or choose name. 
-f | --filename <arg>         Select by filename. 
-u | --url <arg>              Select or choose by URL 
     --produced-on <arg>      Select a date.
-a | --authors <arg>          Select or choose a set of authors. 
     --signature <arg>        Select or choose a signature. 
     --key <arg>              Select or choose a key. 
     --fingerprint <arg>      Select or choose a fingerprint.
     --extra <arg>            

General:
     --file                   Where is the default file? 
     --folder                 Where is the default folder? 
	  --default                What is the default (?)?
     --default                Show me additional information.
     --install <arg>          Install this to a certain location. 
     --uninstall              Uninstall this. 
-v | --verbose                Be verbose in output.
-h | --help                   Show this help and quit.
"
   exit $STATUS
}


# Die if no arguments received.
[ -z "$BASH_ARGV" ] && printf "Nothing to do\n" > /dev/stderr && usage 1

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
     -l|--load-needs)
         DO_LOAD_NEEDS=true
         shift
         LOAD_NEEDS="$1"
      ;;
     -v|--version)
         DO_VERSION=true
         shift
         VERSION="$1"
      ;;
     -u|--uuid)
         DO_UUID=true
         shift
         UUID="$1"
      ;;
     -d|--description)
         DO_DESCRIPTION=true
         shift
         DESCRIPTION="$1"
      ;;
     -s|--summary)
         DO_SUMMARY=true
         shift
         SUMMARY="$1"
      ;;
     -t|--title)
         DO_TITLE=true
         shift
         TITLE="$1"
      ;;
     -n|--namespace)
         DO_NAMESPACE=true
         shift
         NAMESPACE="$1"
      ;;
     -f|--filename)
         DO_FILENAME=true
         shift
         FILENAME="$1"
      ;;
     -u|--url)
         DO_URL=true
         shift
         URL="$1"
      ;;
     --produced-on)
         DO_PRODUCED_ON=true
         shift
         PRODUCED_ON="$1"
      ;;
     --authors)
         DO_AUTHORS=true
         shift
         AUTHORS="$1"
      ;;
     --primary-author)
         DO_AUTHORS=true
         shift
         PRIMARY_AUTHOR="$1"
      ;;
     --signature)
         DO_SIGNATURE=true
         shift
         SIGNATURE="$1"
      ;;
     --key)
         DO_KEY=true
         shift
         KEY="$1"
      ;;
     --fingerprint)
         DO_FINGERPRINT=true
         shift
         FINGERPRINT="$1"
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
     -v|--verbose)
        VERBOSE=true
      ;;
     -h|--help)
        usage 0
      ;;
	  --reset)
		  	source $BINDIR/.CHAIN
			[ -d "$CHAIN_DIR" ] && rm -rfv $CHAIN_DIR
			[ -f "$BINDIR/.CHAIN" ] && rm -v $BINDIR/.CHAIN
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



# Generate a .CHAIN file.
CHAIN_CONFIG="$BINDIR/.CHAIN"
if [ ! -f "$CHAIN_CONFIG" ]
then
	REMOTE_URL_ROOT=${REMOTE_URL_ROOT}
	REMOTE_GLOBAL_KEY=${REMOTE_GLOBAL_KEY}
	CHAIN_DIR="${CHAIN_DIR:-"$BINDIR/.${PROGRAM}/applications"}"

	echo "
CHAIN_DIR="$CHAIN_DIR"
CHAIN_DB="\$CHAIN_DIR/.CHAIN_DB"
REMOTE_URL_ROOT=$REMOTE_URL_ROOT
REMOTE_GLOBAL_KEY=$REMOTE_GLOBAL_KEY" > $CHAIN_CONFIG

fi


# Grab the CHAIN_CONFIG
source $CHAIN_CONFIG


# Basic information...
# file
[ ! -z $DO_FILE ] && {
   printf '' > /dev/null
}
# folder
[ ! -z $DO_FOLDER ] && {
   printf '' > /dev/null
}

# default
[ ! -z $DO_DEFAULT ] && {
   printf '' > /dev/null
}

# required
[ ! -z $DO_REQUIRED ] && {
   printf '' > /dev/null
}


## Packages
# exists
[ ! -z $DO_EXISTS ] && {
   printf '' > /dev/null
}

# create
[ ! -z $DO_CREATE ] && {
	# If the folder doesn't exist already, then create it.
	[ ! -d "$CHAIN_DIR/$BLOB" ] && mkdir -pv $CHAIN_DIR/$BLOB

	# Make a file for dependencies too, and authors, etc.
	[ ! -d "$CHAIN_DIR/$BLOB/DEPENDENCIES" ] && touch $CHAIN_DIR/$BLOB/DEPENDENCIES

	# Title and summary are always required.
	[ -z "$TITLE" ] || [ -z "$SUMMARY" ] && {
		error -m "No title or summary specified."
	}

	# Put this manifest somewhere.
	{
	echo " 
VERSION=$VERSION
UUID=${UUID:-`rand`}
DESCRIPTION='$DESCRIPTION'
SUMMARY='$SUMMARY'
TITLE='$TITLE'
NAMESPACE=$NAMESPACE
FILENAME=$FILENAME
URL=$URL
PRODUCED_ON=$PRODUCED_ON
AUTHORS=$AUTHORS
SIGNATURE=$SIGNATURE
KEY=$KEY
FINGERPRINT=$FINGERPRINT
EXTRA=$EXTRA
"
	} > $CHAIN_DIR/$BLOB/MANIFEST 

	# Does file exist in database?
	# If not, add a record to your file based database.
	{ 
		printf "$UUID|"
		printf "$TITLE|"
		printf "$FILENAME\n"
	} > /dev/stdout
}

# remove
[ ! -z $DO_REMOVE ] && {
	# Remove the folder

	# Remove from the file based database.
   printf '' > /dev/null
}

# update
[ ! -z $DO_UPDATE ] && {
   printf '' > /dev/null
}

# needs
[ ! -z $DO_NEEDS ] && {
	# Check that the file being asked to depend on exists.

	# Set the dependence from here.
   printf '' > /dev/null
}

# no_longer_needs
[ ! -z $DO_NO_LONGER_NEEDS ] && {
   printf '' > /dev/null
}

# load_needs
[ ! -z $DO_LOAD_NEEDS ] && {
   printf '' > /dev/null
}


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



## Parameters
# version
[ ! -z $VERSION ] && {
   printf '' > /dev/null
}

# uuid
[ ! -z $UUID ] && {
   printf '' > /dev/null
}

# description
[ ! -z "$DESCRIPTION" ] && {
   printf '' > /dev/null
}

# summary
[ ! -z "$SUMMARY" ] && {
   printf '' > /dev/null
}

# title
[ ! -z $TITLE ] && {
   printf '' > /dev/null
}

# namespace
[ ! -z $NAMESPACE ] && {
   printf '' > /dev/null
}

# filename
[ ! -z $FILENAME ] && {
   printf '' > /dev/null
}

# url
[ ! -z $URL ] && {
   printf '' > /dev/null
}

# produced_on
[ ! -z $PRODUCED_ON ] && {
   printf '' > /dev/null
}

# authors
[ ! -z $AUTHORS ] && {
   printf '' > /dev/null
}

# signature
[ ! -z $SIGNATURE ] && {
   printf '' > /dev/null
}

# key
[ ! -z $KEY ] && {
   printf '' > /dev/null
}

# fingerprint
[ ! -z $FINGERPRINT ] && {
   printf '' > /dev/null
}

# extra
[ ! -z $EXTRA ] && {
   printf '' > /dev/null
}



