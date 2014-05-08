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


# Extra stuff.
CURRENT_PATH="`pwd`"

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


#------------------------------------------------------
# up  - auto increment by one
# down - auto decrement by one
# now - static version declaration
#-----------------------------------------------------#
version() {
	case "$1" in
		up) sed 's/\(VERSION=\).*/\1';;
		down) ;;
		now) ;;
	esac
}


# Choose from array, this is VERY bad programming.  Stop being lazy.
SVAR=
DVAR=
GIVAR=
LIVAR=
EVAR=
MVAR=
TVAR=
CVAR=
save_args() {
	while [ $# -gt 0 ]
	do
		case "$1" in
			-args) shift; SVAR="$SVAR\n$1";;
			-deps) shift; DVAR="$DVAR\n$1";;
			-gi) 	shift; GIVAR="$GIVAR\n$1";;
			-li) 	shift; LIVAR="$LIVAR\n$1";;
			-ex) 	shift; EVAR="$EVAR\n$1";;
			-dir) shift; MVAR="$MVAR\n$1";;
			-file) shift; TVAR="$TVAR\n$1";;
			-depchain) shift; CVAR="$CVAR\n$1";;
			-dump)
				shift
				local TERM=
				case "$1" in
					args) TERM="$SVAR" ;;
					deps) TERM="$DVAR" ;;
					gi) TERM="$GIVAR" ;;
					li) TERM="$LIVAR" ;;
					ex) TERM="$EVAR" ;;
					dir) TERM="$MVAR" ;;
					depchain) TERM="$CVAR" ;;
					file) TERM="$TVAR" ;;
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
}



# eat_dependencies
LACK_DEPS="$CACHE_DIR/tmp/lack"		# Generate?
CHECK_DEPS="$CACHE_DIR/tmp/check"	# Generate?

eat_dependencies() {
	# if -f DEPENDENCIES
	while read line
	do
		# Was it already tracked as non-existent?
		# sed "s/^$line\n/" 

		# Check that the thing exists.
		not_exists "$line"

		# Find the directory for this file. 
		DEP_FOLDER="$CACHE_DIR/$(grep --line-number "|$line|" $CACHE_DB | \
			sed 's/|/:/g' | \
			awk -F ':' '{ print $4 }')"

		# Does it exist?
		[ ! -d "$DEP_FOLDER" ] && {
			printf "$line\n" >> $LACK_DEPS
			continue
		}
		
		# Find a dependencies file within that directory.
		[ -f "$DEP_FOLDER/$DEPENDENCIES" ] && {
			printf "$line\n" >> $CHECK_DEPS
		}
	done
	# fi
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
    --master <arg>           Update the master branch. 
-n, --needs <arg>            Set a dependence. 
-x, --no-longer-needs <arg>  Unset a dependency. 
    --list-needs <arg>       List <arg>'s dependencies.
    --ignore-needs           Disregard dependencies. 
-k, --link-to <arg>          Put a package somewhere.
    --symlink-to <arg>       Put a package somewhere.
    --link-ignore <arg>      Ignore these when linking out.
    --git-ignore <arg>       Ignore these when committing.
    --uninit <arg>           Remove all tracking information from git.
-b, --blob <arg>             Select by name. 
-u, --uuid <arg>             Select by unique identifier. 

Parameter tuning:
    --version <arg>          Select or choose version. 
-s, --summary <arg>          Select or choose summary. 
    --produced-on <arg>      Select a date.
-a, --authors <arg>          Select or choose a set of authors. 
-q, --extra <arg>            Supply key value pairs of whatever else 
	                          should be tracked in a package. 

General:
    --set-cache-dir <arg>    Set the cache directory to <arg>
    --required <arg>         Define parameters required when creating a package.
    --cd <arg>               Use <arg> as the current cache directory.
	                          (Will fail if .CACHE_DB is not there.)
-i, --info <pkg>             Display all information about a package.
	 --list-versions <arg>    List all the versions out.
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
	  --mkdir)
		   DO_MKDIR=true
			shift
			save_args -dir	"$1"
		;;
	  --touch)
		   DO_TOUCH=true
			shift
			save_args -file "$1"
		;;
	  --no-mkdir)
		   NO_MKDIR=true
		;;
	  --no-touch)
		   NO_TOUCH=true
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
	  -b|--blob)
		   shift
			BLOB="$1"
		;;
     -m|--commit)
         DO_COMMIT=true
         shift
         BLOB="$1"
      ;;
     --master)
         DO_COMMIT_MASTER=true
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
         VERSION_NAME="$1"
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
     --set-cache-dir)
         DO_SET_CACHE_DIR=true
		   shift
         CACHE_DIR="$1"
      ;;
     --install)
         DO_INSTALL=true
         shift
         INSTALL_DIR="$1"
      ;;
     --uninstall)
         DO_UNINSTALL=true
      ;;
     --dist-info)
         DO_DIST_INFO=true
      ;;
     --cd)
         DO_CHANGE_DIR=true
			shift
			CHANGED_DIR="$1"
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
     --required)
         DO_REQUIRED=true
         shift
         REQUIRED="$1"
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


# Always should have a configuration file.
CACHE_CONFIG="$BINDIR/.CACHE"


# Set a cache directory first.
[ ! -z $DO_SET_CACHE_DIR ] && {
	# Was a cache directory given?
	[ -z "$CACHE_DIR" ] && error -e 1 -m "No cache directory specified."

	# Get the fullpath.
	CACHE_DIR=`get_fullpath $CACHE_DIR`
	[ ! -z $VERBOSE ] && printf "New cache dir is at: $CACHE_DIR\n"

	# Make the directory.
	[ ! -d "$CACHE_DIR" ] && mkdir -pv $CACHE_DIR

	# Update the configuration file and move the old data. 
	[ -f "$CACHE_CONFIG" ] && {
		# First, keep a record of the old directory.
		OLD_CACHE_DIR=`sed -n '/^CACHE_DIR=/p' $CACHE_CONFIG | sed "s/^CACHE_DIR=//"`

		# Move the old data to the new directory.
		[ -d "$OLD_CACHE_DIR" ] && {
			mv -v $OLD_CACHE_DIR/* $CACHE_DIR
			mv -v $OLD_CACHE_DIR/.CACHE_DB $CACHE_DIR/.CACHE_DB
			rmdir -pv $OLD_CACHE_DIR 2>/dev/null  # Only removes empty dirs...
		}

		# Update the configuration file.
		sed -i "s|^\(CACHE_DIR=\).*|\1$CACHE_DIR|" $CACHE_CONFIG
	}
}


# Generate a configuration file.
if [ ! -f "$CACHE_CONFIG" ]
then
	REMOTE_URL_ROOT=${REMOTE_URL_ROOT}
	REMOTE_GLOBAL_KEY=${REMOTE_GLOBAL_KEY}
	echo $CACHE_DIR
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

# Get information on your current instance of cache.
[ ! -z $DO_DIST_INFO ] && { 
	source $CACHE_CONFIG
	printf "Cache Directory:          $CACHE_DIR\n"
	printf "Cache Database:           $CACHE_DB\n"
	printf "Default Version:          $DEFAULT_VERSION\n"
	printf "Deployment Type:          $COPY_TYPE\n"
	printf "Folder Name Format:       $FORMAT\n"
	printf "Custom Formatting:        $FORMAT_CUSTOM\n"
	printf "Default remote URL root:  ${REMOTE_URL_ROOT:-None}\n"
	printf "Default global key:       ${REMOTE_GLOBAL_KEY:-None}\n"
}

## Packages
# exists
[ ! -z $DO_EXISTS ] && not_exists $BLOB

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
	INSTALL="$FOLDER/INSTALL"
	README="$FOLDER/README.md"
	GITIGNORE="$FOLDER/.gitignore"
	# RSYNCIGNORE="$FOLDER/.rsyncignore"
	LINKIGNORE="$FOLDER/.linkignore"

	FILE_ARR=(
		"$FOLDER" 
		"$DEPENDENCIES" 
		"$MANIFEST" 
		"$VERSIONS" 
		"$INSTALL" 
		"$README"
		"$GITIGNORE"
	#	"$RSYNCIGNORE"
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
	[ -z $NO_MKDIR ] && {
		for D in ${DIR_ARR[@]}; do [ ! -d "$D" ] && mkdir -pv $D; done
	}

	[ -z $NO_TOUCH ] && {
		for F in ${FILE_ARR[@]}; do [ ! -f "$F" ] && touch $F; done
	}

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

	# Do not link certain files by default.
	# echo MANIFEST >> $LINKIGNORE
	# echo DEPENDENCIES >> $LINKIGNORE
	# echo VERSION >> $LINKIGNORE
	#

	# Do not track VERSION by default.
	echo VERSIONS >> $GITIGNORE
	
	# A file called SUMMARY can keep all important information in one place.

	# Does file exist in database?
	# If not, add a record to your file based database.
	{ 
		printf "$UUID|"
		printf "$TITLE|"
		printf "`basename $FOLDER`\n"
	} >> $CACHE_DB

	# Add some version information (we always assume this is the first one).
	CURRENT_VERSION=`rand`
	{ 
		printf "1|"						# Number
		printf "$CURRENT_VERSION|"	# ID
		printf "`date`|"				# Date 
		printf "$VERSION_NAME|"		# Name (proper version name, like 2.12)
		printf "*INITIAL"				# Commit/version type
		printf "\n"
	} > $VERSIONS


	# Finally, start with the version control madness.
	cd $FOLDER
	#echo "Initializing Git repository for $BLOB..."
	git init
	#echo "Adding all files..."
	git add .
	# GIT_ID=`sed -n -e '/^UUID=/p' $FOLDER/MANIFEST | sed 's/UUID=//'`
	#echo "Running initial commit..."
	git commit -m "cache_$CURRENT_VERSION committed on `date`"
	#echo "Creating new branch for $CURRENT_VERSION..."
	git branch "$CURRENT_VERSION"		
	if [ -z `git branch | grep -v 'master'` ] 
	then
		error -m "Not able to track '$BLOB' repository." -p "cache"
	else
		echo "Repository creation successful."
	fi
	cd $CURRENT_PATH
}


# remove
[ ! -z $DO_REMOVE ] && {
	# Is it there?
	not_exists $BLOB

	# Find entry in the file based database.
	ENTRY=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g'`
	# printf "$ENTRY\n" | awk -F ':' '{ print $4 }'
	LINE=`printf "$ENTRY\n" | awk -F ':' '{ print $1 }'`
	FOLDER="$CACHE_DIR/`printf "$ENTRY\n" | awk -F ':' '{ print $4 }'`"

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


# Make multiple directories
[ ! -z $DO_MKDIR ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"

	# Move through the array and make each thing.
	save_args -dump dir | { 
		FN="`cat /dev/stdin`"
		while read line
		do
			[ ! -z "$line" ] && {
				for the_dir in $(printf "$line\n" | sed "s/,/ /g")
				do
					echo mkdir -pv $FOLDER/$the_dir
					mkdir -pv $FOLDER/$the_dir
				done
			}
		done < $FN
	}
}


# Make multiple files.
[ ! -z $DO_TOUCH ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"

	# Move through the array and make each thing.
	save_args -dump file | { 
		FN="`cat /dev/stdin`"
		while read line
		do
			[ ! -z "$line" ] && {
				for the_file in $(printf "$line\n" | sed "s/,/ /g")
				do
					echo touch $FOLDER/$the_file
					touch $FOLDER/$the_file
				done
			}
		done < $FN
	}
}


# Run a git ignore.
[ ! -z $DO_GIT_IGNORE ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"

	# Move through the array and make each thing.
	save_args -dump gi | { 
		FN="`cat /dev/stdin`"
		GITIG="$FOLDER/.gitignore"
		while read line
		do
			[ ! -z "$line" ] && {
				for tf in $(printf "$line\n" | sed "s/,/ /g")
				do
					test -z "`sed -n "/^$tf/p" $GITIG`" && printf "$tf\n" >> $GITIG
				done
			}
		done < $FN
	}
}


# Run a link ignore.
[ ! -z $DO_LINK_IGNORE ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"

	# Move through the array and make each thing.
	save_args -dump li | { 
		FN="`cat /dev/stdin`"
		LINKIG="$FOLDER/.linkignore"
		while read line
		do
			[ ! -z "$line" ] && {
				for tf in $(printf "$line\n" | sed "s/,/ /g")
				do
					test -z "`sed -n "/^$tf/p" $LINKIG`" && printf "$tf\n" >> $LINKIG
				done
			}
		done < $FN
	}
}


# Commit
# 1. add a branch corresponding to the version, just stash changes so that they don't get lost.
# 2. Or commit to that new branch.
[ ! -z $DO_COMMIT ] && {
	# Anything given?
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"

	# Is it there?
	not_exists $BLOB

	# Find entry.
	FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"

	# Define the manifest
	VERSIONS="$FOLDER/VERSIONS"

	# Replace the current versions.
	sed -i 's/*CURRENT/*CHECKPOINT/' $VERSIONS

	# Print the new copy off.
	CURRENT_VERSION=`rand`
	{ 
		printf "$(( $(sed -n \$p $VERSIONS | awk -F '|' '{ print $1 }') + 1 ))|"
		printf "$CURRENT_VERSION|"
		printf "`date`|"
		printf "$VERSION_NAME|"
		printf "*CURRENT" 
		printf "\n"
	} >> $VERSIONS

	# echo "Changing to directory: $FOLDER..."
	cd $FOLDER
	git add .
	git branch $CURRENT_VERSION
	git checkout $CURRENT_VERSION
	git commit -m "cache $CURRENT_VERSION - `date`"
	git checkout master
	cd $CURRENT_PATH
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

	# Check that each dependency exists. 
#	save_args -dump deps | { FN=`cat /dev/stdin`; while read line
#	do
#		# Find entry and delete it.
#		sed -i "/^${line}$/d" $DEPENDENCIES
#	done < $FN; }

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

	cat $DEPENDENCIES | awk -F '|' '{ print $1 }'
}


# assess needs (are all the dependencies on this system?)
[ ! -z $DO_ASSESS_NEEDS ] && { printf '' > /dev/null; }


# Link to
[ ! -z $DO_LINK_TO ] || [ ! -z $DO_SYMLINK_TO ] && {
  	# Make sure an application and destination directory has been specified.
	[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "cache"
	[ -z "$LINK_TO" ] && error -e 1 -m "No location specified for linking." -p "cache"
	
	# Make sure the main application exists.  Initial folder search will fail if not.
	not_exists "$BLOB"

	# Also get the initial folder. 
	SEED_FOLDER="$CACHE_DIR/`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`"

	# Save it or die.
	if [ -z "$SEED_FOLDER" ]
	then
		error -e 1 -m "Cannot find source folder: $SEED_FOLDER for application '$BLOB'"
	else	
		save_args -depchain "$BLOB|$SEED_FOLDER"
	fi

	# If there's a dependency list, loop through each entry 
	# and pull those folders.
	[ -z "$DO_IGNORE_NEEDS" ] && {
		# Define the name of our file.
		DEPENDENCIES="$SEED_FOLDER/DEPENDENCIES"

		# Search through all the entries here.
		[ -f "$DEPENDENCIES" ] && [ ! -z "`cat $DEPENDENCIES`" ] &&  {
			# Get the folder name.
			echo "HARAM!!!"
		
			# Save both to the dependency chain.
		}
	}
	exit
	# Compile a list of the application id and it's dependencies.
	# For each dependency, save it to arg. 
		
	
		# Get the application's folder if available, dying if not.
		# (Unless ignoring dependencies.)

		# Change directory and switch to *CURRENT branch unless not default. 

		# Link while we are on this branch.

		# Switch back to 'master'


	# Find entry.
	FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
		awk -F ':' '{ print $4 }'`
	
	# Expand the destination directory if not absolute.
	LINK_TO=`get_fullpath $LINK_TO`

	# Error out if the folder exists.
	[ -d "$LINK_TO" ] && {
		error -e 1 -m "'$LINK_TO' already exists.\nNot relinking." -p "cache"
	}

	# Run the linking.
	BLOB_ROOT="$CACHE_DIR/$FOLDER"
	NO_LINK="$BLOB_ROOT/.linkignore"
	echo $BLOB_ROOT
	echo $LINK_TO
	echo $NO_LINK
	# exit

	# Set linking flags.
	[ ! -z $VERBOSE ] && LN_FLAGS="-v" || LN_FLAGS=
	[ ! -z $DO_SYMLINK_TO ] && LN_FLAGS="-s $LN_FLAGS" 

	# Get a full directory listing.  -print0?
	for LINK_FILE in `find $BLOB_ROOT | grep -v '.git'` 
	do
		# Move through each file and make sure that it doesn't match what
		# you want excluded.

		# Define a relative root, always cutting the trailing slash.
		RELATIVE_ROOT=`printf "%s" $LINK_FILE | \
			sed "s#${BLOB_ROOT}##" | sed 's#^/##'`

		# Make any directories.
		[ -d "$LINK_FILE" ] && {
			mkdir -pv $LINK_TO/$RELATIVE_ROOT
			continue
		}

		# Hard or soft link any files.
		[ -f "$LINK_FILE" ] && {
			[ -z "$(sed -n "/^$(basename $LINK_FILE)/p" $NO_LINK)" ] && { 
				ln $LN_FLAGS $LINK_FILE $LINK_TO/$RELATIVE_ROOT
				continue
			}
		}
	done
}

# Wipe any open temporary files.
tmp_file -w
