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


# Ignore certain items.
SVAR=
DVAR=
GIVAR=
LIVAR=
EVAR=

save_args() {
	while [ $# -gt 0 ]
	do
		case "$1" in
			-args) shift; SVAR="$SVAR\n$1";;
			-deps) shift; DVAR="$DVAR\n$1";;
			-gi) 	shift; GIVAR="$GIVAR\n$1";;
			-li) 	shift; LIVAR="$LIVAR\n$1";;
			-ex) 	shift; EVAR="$EVAR\n$1";;
			-dump)
				shift
				local TERM=
				case "$1" in
					args) TERM="$SVAR" ;;
					deps) TERM="$DVAR" ;;
					gi) TERM="$GIVAR" ;;
					li) TERM="$LIVAR" ;;
					ex) TERM="$EVAR" ;;
					*) error -e 1 \
						-m "Incorrect item given to save_args -dump." \
						-p "cache: DEVELOPER ERROR"
					;;
				esac
				# local ARGDUMP=`random -f -l 6 | tr '[0-9]' '_' | sed 's/+/_/g'`
				tmp_file -n ARGDUMP
				printf "$TERM\n" > $ARGDUMP
				printf "$ARGDUMP"
			;;
		esac
	shift
	done
#	SVAR="$SVAR\n$1"	
}

DVAR=
save_deps() {
	DVAR="$DVAR\n$1"	
}


# usage - Show usage message and die with $STATUS
usage() {
   STATUS="${1:-0}"
   echo "Usage: ./$PROGRAM
	[ -  ]
Database stuff:
-e, --exists <arg>           Does this file exist? 
-c, --create <arg>           Add a package. 
    --mkdir <arg>            Make additional directories. 
    --touch <arg>            Create additional files.
-r, --remove <arg>           Remove a package. 
-u, --update <arg>           Update a package. 
-m, --commit <arg>           Commit changes to a package.
-n, --needs <arg>            Set a dependence. 
-x, --no-longer-needs <arg>  Unset a dependency. 
    --list-needs <arg>            Set a dependence. 
-k, --link-to <arg>          Put a package somewhere.
    --symlink-to <arg>       Put a package somewhere.
    --link-ignore <arg>      Ignore these when linking out.
    --git-ignore <arg>       Ignore these when committing.

Parameter tuning:
-q, --required <arg>         Which parameters are required when creating a package? 
    --version <arg>          Select or choose version. 
-u, --uuid <arg>             Select by UUID. 
-s, --summary <arg>          Select or choose summary. 
    --description <arg>      Select or choose description. 
    --title <arg>            Select or choose title. 
    --namespace <arg>        Select or choose name. 
-f, --filename <arg>         Select by filename. 
-u, --url <arg>              Select or choose by URL 
    --produced-on <arg>      Select a date.
-a, --authors <arg>          Select or choose a set of authors. 
    --signature <arg>        Select or choose a signature. 
    --key <arg>              Select or choose a key. 
    --fingerprint <arg>      Select or choose a fingerprint.
    --extra <arg>            Supply key value pairs of whatever else 
	                          should be tracked in a package. 

General:
-i, --info <pkg>             Display all information about a package.
    --contents <pkg>         Display all contents of a package.
-l, --list                   List all packages.
-d, --directory              Where is an application's home directory? 
    --dist-info              Display information about how \`$PROGRAM\` is setup
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
	  -k|--link-to)
		   DO_LINK_TO=true
			shift
			LINK_TO="$1"
		;;
	  --symlink-to)
		   DO_SYMLINK_TO=true
			shift
			LINK_TO="$1"
		;;
	  --git-ignore) 
		   DO_GIT_IGNORE=true
		   shift
			save_args -gi "$1"
		;;
	  --link-ignore) 
		   DO_LINK_IGNORE=true
		   shift
			save_args -li "$1"
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
         save_args -deps "$1"
      ;;
     -x|--no-longer-needs)
         DO_NO_LONGER_NEEDS=true
         shift
         save_args -deps "$1"
      ;;
     --list-needs)
         DO_LIST_NEEDS=true
			shift
			BLOB="$1"
      ;;
     -s|--summary)
         DO_SUMMARY=true
         shift
         SUMMARY="$1"
      ;;
     --version)
         DO_VERSION=true
         shift
         save_args -args "VERSION=$1"
      ;;
     -u|--uuid)
         DO_UUID=true
         shift
         UUID="$1"
      ;;
     --description)
         DO_DESCRIPTION=true
         shift
			save_args -args "DESCRIPTION=$1"
      ;;
     -t|--title)
         DO_TITLE=true
         shift
         save_args -args "TITLE=$1"
      ;;
     -n|--namespace)
         DO_NAMESPACE=true
         shift
         save_args -args "NAMESPACE=$1"
      ;;
     -f|--archive)
         DO_ARCHIVE=true
         shift
         save_args -args "ARCHIVE=$1"
      ;;
     -u|--url)
         DO_URL=true
         shift
         save_args -args "URL=$1"
      ;;
     --produced-on)
         DO_PRODUCED_ON=true
         shift
         save_args -args "PRODUCED_ON=$1"
      ;;
     --authors)
         DO_AUTHORS=true
         shift
         save_args -args "AUTHORS=$1"
      ;;
     --primary-author)
         DO_AUTHORS=true
         shift
         save_args -args "PRIMARY_AUTHOR=$1"
      ;;
     --signature)
         DO_SIGNATURE=true
         shift
         save_args -args "SIGNATURE=$1"
      ;;
     --key)
         DO_KEY=true
         shift
         save_args -args "KEY=$1"
      ;;
     --fingerprint)
         DO_FINGERPRINT=true
         shift
         save_args -args "FINGERPRINT=$1"
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
     -d|--dir|--directory)
         DO_FOLDER=true
			shift
			BLOB="$1"
      ;;
     -i|--info)
        DO_INTERPRET=true
		  shift
		  BLOB="$1"
      ;;
     --contents)
        DO_DUMP_CONTENTS=true
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
	  --test)
		  shift
		  case "$1" in 
			  args) TEST=args;;
			  deps) TEST=deps;;
			  gi) TEST=gi;;
			  li) TEST=li;;
			  ex) TEST=ex;;
	     esac
		  save_args -dump $TEST | { 
				FN=`cat /dev/stdin`
				while read line 
				do
					[ ! -z "$line" ] && echo $line
				done < $FN
		  }
		  exit
		;;
	  --reset)
		  	source $BINDIR/.CACHE
			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
			exit
		;;
	  --total-reset)
		  	source $BINDIR/.CACHE
			init --uninstall
			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
			exit
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
  	init --fatal-if-missing "git,grep,sed,awk,mkdir" 

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
CACHE_DIR=\"$CACHE_DIR\"
CACHE_DB=\"\$CACHE_DIR/.CACHE_DB\"
DEFAULT_VERSION=0.01
COPY_TYPE=LINKED                 # LINKED, STATIC
FORMAT=DATESTAMP						# UUID, NONE, and CUSTOM are other choices.
FORMAT_CUSTOM=
REMOTE_URL_ROOT=$REMOTE_URL_ROOT
REMOTE_GLOBAL_KEY=$REMOTE_GLOBAL_KEY" > $CACHE_CONFIG
fi


# Grab the CACHE_CONFIG
source $CACHE_CONFIG


# Basic information...
# folder
[ ! -z $DO_FOLDER ] && {
	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Show the folder.
  	printf "%s\n" "$CACHE_DIR/$FOLDER" 
}


# Dump contents
[ ! -z $DO_DUMP_CONTENTS ] && {
	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# List everything out.
	ls $CACHE_DIR/$FOLDER
}


# List 
[ ! -z $DO_LIST ] && {
	awk -v "cache_dir=$CACHE_DIR" -F '|' '{
		print "App Name:      " $2
		print "App ID:        " $1
		print "App Location:  " $3
		print "Full Path:     " cache_dir"/"$3
		print "\n"
	}' $CACHE_DB 
}


## Packages
# exists
[ ! -z $DO_EXISTS ] && {
	exists $BLOB
}

# required
[ ! -z $DO_REQUIRED ] && {
   printf '' > /dev/null
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

	# Common vars and files.
	FOLDER="$CACHE_DIR/${BLOB}.${FORMAT}"
	DEPENDENCIES="$FOLDER/DEPENDENCIES"
	MANIFEST="$FOLDER/MANIFEST"
	VERSIONS="$FOLDER/VERSIONS"
	INFO="$FOLDER/INFO"
	INSTALL="$FOLDER/INSTALL"
	README="$FOLDER/README"
	GITIGNORE="$FOLDER/.gitignore"
	RSYNCIGNORE="$FOLDER/.rsyncignore"
	LINKIGNORE="$FOLDER/.linkignore"

	FILE_ARR=(
		"$FOLDER" 
		"$DEPENDENCIES" 
		"$MANIFEST" 
		"$VERSIONS" 
		"$INFO" 
		"$INSTALL" 
		"$README"
		"$GITIGNORE"
		"$RSYNCIGNORE"
		"$LINKIGNORE"
	)

	DIR_ARR=(
		"$FOLDER/src"
		"$FOLDER/tests"
		"$FOLDER/docs"
	)

	# If the folder doesn't exist already, then create it.
	[ ! -d "$FOLDER" ] && mkdir -pv $FOLDER

	# Make all the needed files and folders.
	for F in ${FILE_ARR[@]}; do [ ! -f "$F" ] && touch $F; done
	for D in ${DIR_ARR[@]}; do [ ! -d "$D" ] && mkdir -pv $D; done

	# Put this manifest somewhere.
	{
		echo "VERSION=${VERSION-$DEFAULT_VERSION}
UUID=$UUID
DESCRIPTION='$DESCRIPTION'
SUMMARY='$SUMMARY'
TITLE='$TITLE'
NAMESPACE=$NAMESPACE
URL=$URL
ARCHIVE=$ARCHIVE
PRODUCED_ON=$PRODUCED_ON
AUTHORS=$AUTHORS
SIGNATURE=$SIGNATURE
KEY=$KEY
FINGERPRINT=$FINGERPRINT"
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
	printf "$SVAR\n" > $JELLY

	# Go over each.
	while read line 
	do
		# Get the matching thing.
		TERM=`printf "$line" | awk -F '=' '{ print $1 }'` 
		VALUE=`printf "$line" | awk -F '=' '{ print $2 }'` 

		# Run replacements.
		if [ ! -z "`sed -n "/^${TERM}=/p" $MANIFEST`" ] 
		then
			# Run a permanent replacement with sed.
			sed -i "s|^\(${TERM}=\).*|\1\"${VALUE}\"|" $MANIFEST
		else
			# Just append it otherwise.
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
				sed 's/=/:/g' | awk -F ':' '{
					printf "%-15s %s\n", $1":", $2
				}'
		}
	done < $MANIFEST

	# Show the dependencies too.
	DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
	printf "Depends On:\n"
	cat $DEPENDENCIES
}


# Set and manage dependencies.
# needs
[ ! -z $DO_NEEDS ] && {
	# Check that the file being asked to depend on exists.
	# One at a time for now.

	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"
	[ -z "$DVAR" ] && error -e 1 -m "No dependencies specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Define the manifest
	DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
	[ ! -f $DEPENDENCIES ] && touch $DEPENDENCIES

	# Track dependents
	tmp_file -n DEPS
	printf "$DVAR\n" > $DEPS

	# Check that each dependency exists. 
	while read line
	do
		# If something doesn't exist, shut down and don't append.
		not_exists $line

		# Check if that line is already there.
		[ -z "`sed -n "/^${line}/p" $DEPENDENCIES`" ] && {
			printf -- "%s\n" "$line"  >> $DEPENDENCIES
		}
	done < $DEPS
}


# no_longer_needs
[ ! -z $DO_NO_LONGER_NEEDS ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"
	[ -z "$DVAR" ] && error -e 1 -m "No dependencies specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Define the manifest
	DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
	[ ! -f $DEPENDENCIES ] && error -e 1 -m "No file found for dependency tracking.\nPerhaps this file had no dependencies?\n" -p "cache"

	# Track dependents
	tmp_file -n DEPS
	printf "$DVAR\n" > $DEPS

	# Check that each dependency exists. 
	while read line
	do
		# Find entry and delete it.
		sed -i "/^${line}$/d" $DEPENDENCIES
	done < $DEPS
}


# list needs (list the dependencies for a file)
[ ! -z $DO_LIST_NEEDS ] && { 
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Find dependencies
	DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
	[ ! -f $DEPENDENCIES ] && error -e 1 -m "No file found for dependency tracking.\nPerhaps this file had no dependencies?\n" -p "cache"

	# List them out.
	LIST=`cat $DEPENDENCIES | sed '/^$/d'`
	COUNT=`cat $DEPENDENCIES | sed '/^$/d' | wc -l`
	
	if [ $COUNT -gt 1 ] 
	then 
		printf "$COUNT dependencies found for '$BLOB':\n"
	elif [ $COUNT -eq 1 ]
	then 
		printf "$COUNT dependency found for '$BLOB':\n"
	fi
	cat $DEPENDENCIES
}


# assess needs (are all the dependencies on this system?)
[ ! -z $DO_ASSESS_NEEDS ] && { printf '' > /dev/null; }


# Link to
[ ! -z $DO_LINK_TO ] || [ ! -z $DO_SYMLINK_TO ] && {
  	# Make sure an application and destination directory has been specified.
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"
	[ -z "$LINK_TO" ] && error -e 1 -m "No location specified for linking." -p "cache"

	# Make sure the application exists.
	not_exists "$BLOB"

	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`

	# Expand the directory if not absolute.
	LINK_TO=`get_fullpath $LINK_TO`

	# Error out if the folder exists.
	[ -d "$LINK_TO" ] && {
		error -e 1 -m "'$LINK_TO' already exists.\nNot relinking." -p "cache"
	}

	# Run the linking.
	BLOB_ROOT="$CACHE_DIR/$FOLDER"

	# Set linking flags.
	[ ! -z $VERBOSE ] && LN_FLAGS="-v" || LN_FLAGS=
	[ ! -z $DO_SYMLINK_TO ] && LN_FLAGS="-s $LN_FLAGS" 

	# Get a full directory listing.  -print0?
	for LINK_FILE in `find $BLOB_ROOT | grep -v '.git'` 
	do
		# Move through each file and make sure that it doesn't match what
		# you want excluded.

		# Define a relative root.
		RELATIVE_ROOT=`printf "%s" $LINK_FILE | sed "s#$BLOB_ROOT##"`

		# Make any directories.
		[ -d "$LINK_FILE" ] && {
			mkdir $MKDIR_FLAGS $LINK_TO/$RELATIVE_ROOT
			continue
		}

		# Hard link any files.
		[ -f "$LINK_FILE" ] && {
			ln $LN_FLAGS $LINK_FILE $LINK_TO/$RELATIVE_ROOT
			continue
		}
	done
}

# Wipe any open temporary files.
tmp_file -w
