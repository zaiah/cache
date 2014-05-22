#!/bin/bash -
#-----------------------------------------------------#
# cache
#
# A database-less way to manage dependencies.
#-----------------------------------------------------#
#-----------------------------------------------------#
# Licensing
# ---------
# Copyright (c) 2014 Vent Industries, LLC
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
function cache () {
	# Local variables
	local TMP_FREEZE= DIFF_BEFORE_EXPAND= NEWEST_WHEN_EXPANDING= CHECK_FILE= UNIX_FILE= SCANDIR_LEVEL= ARCHIVE= ARGDUMP= ARR_DEPTH= ARR_ELEMENTS= AT= AUTHORS= AVAR= BINDIR= BLOB= BLOB_NAME= BLOB_ROOT= CACHE_CONFIG= CACHE_DB= CACHE_DIR= CACHE_OPTIONS= CHANGED_DIR= CO= COPY_TYPE= COUNT= CURRENT_FILE_POS= CURRENT_PATH= CURRENT_VERSION= CVAR= DEFAULT_VERSION= DEPENDENCIES= DEP_FOLDER= DESCRIPTION= DIR_ARR= DO_ADD_CACHE_OPTIONS= DO_AUTHORS= DO_CHANGE_DIR= DO_COMMIT= DO_COMMIT_MASTER= DO_CONVERT= DO_COPY_TO= DO_CREATE= DO_DIST_INFO= DO_DUMP_CONTENTS= DO_EXISTS= DO_EXTRA= DO_FOLDER= DO_FREEZE= DO_GIT_IGNORE= DO_IGNORE_NEEDS= DO_INSTALL= DO_INTERPRET= DO_LINK_IGNORE= DO_LINK_TO= DO_LIST= DO_LIST_NEEDS= DO_MKDIR= DO_NEEDS= DO_NO_LONGER_NEEDS= DO_PRODUCED_ON= DO_REGISTER= DO_REMOVE= DO_REQUIRED= DO_SET_CACHE_DIR= DO_SUMMARY= DO_SYMLINK_TO= DO_TOUCH= DO_UNINSTALL= DO_UPDATE= DO_UUID= DO_VERSION= DVAR= END_OF_FILE= ENTRY= EVAR= DO_EXPAND= EXCLUDE= EXPANSION_DIR= EXTRA= FILE_ARR= FN= FOLDER= FORMAT= FORMAT_CUSTOM= FREEZE_AT= GIT_ID= GITIG= GITIGNORE= GIVAR= INSTALL= INSTALL_DIR= LINE= LINKIG= LINKIGNORE= LINK_TO= LIST= LIVAR= LN_FLAGS= MANIFEST= MVAR= NAME= NAMESPACE= NO_LINK= NO_MKDIR= NO_TOUCH= OLD_CACHE_DIR= PRODUCED_ON= README= RELATIVE_ROOT= REMOTE_GLOBAL_KEY= REMOTE_URL_ROOT= REQUIRED= SEED_FOLDER= SELF= STATUS= SUMMARY= SVAR= TITLE= TVAR= URL= UUID= VALUE= VERBOSE= VERSION_NAME= VERSIONS= 
	
	# References to $SELF
	BINDIR="$(dirname "$(readlink -f $0)")"
	SELF="$(readlink -f $0)"
	
	# Extra stuff.
	CURRENT_PATH="`pwd`"
	
	# Error
	error() {
		# Names and variables.
		local LIBPROGRAM="error"
		local ERR_FILE="/dev/stderr"  # this could be a few other places.	
		local PREFIX="ERROR:"
		local MESSAGE= EXIT_CODE= DO_STDERR= VERBOSE=
		
		# error_usage - Show usage message and die with $STATUS
		error_usage() {
			STATUS="${1:-0}"
			echo "Usage: ./$LIBPROGRAM
			[ -  ]
		
		-l | --log <arg>              Send error messages to log file <arg> 
		-m | --message <arg>          Send an error message along with something.
		-e | --exit <sig>             Exit with <sig> besides default code of 1.
		-s | --stderr                 Use /dev/stderr as typical error handler.
		-p | --program <name>         Die with program name.
		-v | --verbose                Be verbose in output.
		-h | --help                   Show this help and quit.
		"
			exit $STATUS
		}
		
		
		# Die if no arguments received.
		[ -z "$#" ] && printf "Nothing to do\n" > /dev/stderr && error_usage 1
		
		# Process options.
		while [ $# -gt 0 ]
		do
			case "$1" in
			-m|--message) shift; MESSAGE="$1" ;;
			-l|--log) DO_LOG=true; shift;	ERR_FILE="$1";;
			-e|--exit)	DO_EXIT=true; shift;	EXIT_CODE="$1"	;;
			-s|--stderr) DO_STDERR=true;;
			-p|--program)	shift; PREFIX="$1";;
			-v|--verbose) VERBOSE=true;;
			-h|--help) error_usage 0 ;;
			--) break;;
			-*)
				printf "Unknown argument received: $1\n" > /dev/stderr;
				error_usage 1
			;;
			*) break;;
			esac
		shift
		done

		# Use default error reporting.
		[ ! -z $DO_STDERR ] && ERR_FILE="/dev/stderr"

		# Display error message.
		printf -- "${PREFIX}: $MESSAGE\n" >> $ERR_FILE

		# Exit if this is a big deal.
		[ ! -z $DO_EXIT ] && exit $EXIT_CODE

		# Unsets
		unset LIBPROGRAM MESSAGE EXIT_CODE DO_STDERR VERBOSE
	}

	# Fetch a random number out of nowhere.
	rand() { random -l 40 | sed 's#/#_#g' | sed 's#=#+#g'; }
	
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
	SVAR= DVAR= GIVAR= LIVAR= EVAR= MVAR= TVAR= CVAR= 
	save_args() {
		while [ $# -gt 0 ]
		do
			case "$1" in
				-files) shift; AVAR="$SVAR\n$1";;
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
						files) TERM="$AVAR" ;;
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

	# Get a file inode or return 1.
	get_inode() {
		if [ ! -z "$1" ]
		then
			if [ -f "$1" ] || [ -L "$1" ]
			then
				ls --inode $1 | awk '{ print $1 }'
			else
				printf 0
			fi
		else
			printf 0
		fi	
	}
	
	ARR_ELEMENTS=
	ARR_DEPTH=20
	get_position() {
		cfile=$1
		cline=$2
		[ -f "$cfile" ] && {
			echo 'Checking file positiion.'
			# Get positions.
			END_OF_FILE=`sed -n '$=' $cfile 2>/dev/null`
			CURRENT_FILE_POS=`sed -n "/^$cline/ =" $cfile  2>/dev/null`
			#echo ${ARR_ELEMENTS[@]}
	
			# Have we reached the end of the file?  Say so.
			[ $END_OF_FILE -eq $CURRENT_FILE_POS ] && {
				echo "We've reached the end of $cfile"
				# Remove the file from the array. (or lower the level)
				for n in ${ARR_ELEMENTS[@]}; do
					if [ $n == $cfile ]; then
						arr -x "$n" --from ARR_ELEMENTS
					fi
				done
			}
		}
	}
	
	
	tmp_file -n LACK_DEPS
	tmp_file -n CHECK_DEPS
	tmp_file -n GRAB_DEPS
	# eat_dependencies
	eat_dependencies() {
		# ...
		[ -f "$1" ] && [[ `in_arr -a ARR_ELEMENTS -t "$1"` == "false" ]] && {
			# Add the file.
			arr --push "$1" --to ARR_ELEMENTS
			# echo ${ARR_ELEMENTS[@]}
	
			# Make sure that we're not over the array limit.
			if [ ${#ARR_ELEMENTS[@]} -lt $ARR_DEPTH ]
			then
				# Then move through all the dependencies.
				while read line
				do
					# Only move forward if not blank.
					if [ ! -z "$line" ]
					then
						# Was it already run through?
						# printf "Checking for possibility of application '$line'\n" 
						# printf "already having been processed."
	
						# We have it, skip it.
						# if [ `in_arr -a CHECK_DEPS -t "$line"` ]
						# then
						if [ -f "$CHECK_DEPS" ] && [ ! -z "`sed -n "/^${line}|/p" $CHECK_DEPS`" ] 
						then
							printf "File $line was already found on the system.\n"
							get_position $1 $line
							continue
	
						# We don't have it, skip it.
						# elif [ `in_arr -a LACK_DEPS -t "$line"` ]
						# then
						elif [ -f "$LACK_DEPS" ] && [ ! -z "`sed -n "/^${line}$/p" $LACK_DEPS`" ] 
						then
							echo "File $line was already marked as not present on the system."
							get_position $1 $line
							continue	
	
						# We haven't touched it, evaluate it.
						else
							# Check that the application exists.
							echo "Checking for existence of application: $line"
							[ -z "`cut -f 2 -d '|' $CACHE_DB | sed -n "/^$line$/p"`" ] && {
								# Make a record of its existence.
								printf "Application '$line' not found.\n"
								printf "$line\n" >> $LACK_DEPS
								# arr --push "$line" --to LACK_DEPS
	
								# Have we reached the end of the file?
								get_position $1 $line
								continue
							}
	
							# Find the directory for this file. 
							echo "Checking for home directory of application: $line"
							DEP_FOLDER="$CACHE_DIR/$(grep --line-number "|$line|" $CACHE_DB | \
								sed 's/|/:/g' | \
								awk -F ':' '{ print $4 }')"
	
							# Does it exist?
							if [ -d "$DEP_FOLDER" ]
							then
								# Make a record of the directory.
								printf "$line|$DEP_FOLDER\n" >> $CHECK_DEPS
								# arr --push "$line" --to CHECK_DEPS
								save_args -depchain "$line|$DEP_FOLDER"	
								# printf "$line|$DEP_FOLDER\n" >> $CHECK_DEPS
	
								# Have we reached the end of the file?
								get_position $1 $line
	
								# Find a dependencies file within that directory.
								if [ -f "$DEP_FOLDER/DEPENDENCIES" ] && 
									[ ! -z "`cat $DEP_FOLDER/DEPENDENCIES` 2>/dev/null" ] 
								then 
									eat_dependencies $DEP_FOLDER/DEPENDENCIES
								fi	
							else
								# Make a record that we're missing this directory.
								printf "$line\n" >> $LACK_DEPS
								# arr --push "$line" --to LACK_DEPS
	
								# Have we reached the end of the file?  Say so.
								get_position $1 $line
							fi
						fi	
					fi
				done < $1 
			# ...
			else
				error \
					-m "The dependency chain is too deep for the limit imposed." \
					-p "$PROGRAM" -e 1
				exit 1
			fi	
		}
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
    --register <arg>         Register a package.
    --unregister <arg>       Unregister a package. 
-u, --update <arg>           Update a package. 
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
-m, --commit <arg>           Commit changes to a package.
-p, --push-from <arg>        Push additional files in <arg> to 
                             application directory selected by --blob.

Parameter tuning:
    --version <arg>          Select or choose version. 
-s, --summary <arg>          Select or choose summary. 
    --produced-on <arg>      Select a date.
-a, --authors <arg>          Select or choose a set of authors. 
-q, --extra <arg>            Supply key value pairs of whatever else 
                             should be tracked in a package. 
	
General:
    --set-cache-dir <arg>    Set the cache directory to <arg>
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
	
Under construction:
    --required <arg>         Define parameters required when making a package.
    --populate <arg>         Populate from somewhere.
    --cd <arg>               Use <arg> as the current cache directory.
                             (Will fail if .CACHE_DB is not there.)
    --diff-before            Run a diff before merging.
    --newest                 Use the newest copy of a file by default when 
                             expanding.
"
	   exit $STATUS
	}
	
	
	# Die if no arguments received.
	[ -z "$#" ] && printf "Nothing to do\n" > /dev/stderr && usage 1
	
	
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
		  --freeze)
			   DO_FREEZE=true
				shift
				FREEZE_AT="$1"
			;;
		  --copy-to)
			   DO_COPY_TO=true
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
	      --use-branches)
	         USE_BRANCHES=true
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
	     --ignore-needs)
	         DO_IGNORE_NEEDS=true
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
	     --produced-on)
	         DO_PRODUCED_ON=true
	         shift
	         save_args -args "PRODUCED_ON=$1"
	      ;;
	     -a|--authors)
	         DO_AUTHORS=true
	         shift
	         save_args -args "AUTHORS=$1"
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
	     -z|--cache-options)
			   DO_ADD_CACHE_OPTIONS=true
				shift
				CO="`printf "$1" | tr [a-z] [A-Z] | tr '[:blank:]' _ | tr - _`"
				save_args -args "${CO}"
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
		  --register)
	         DO_REGISTER=true
	         shift
	         AT="$1"
	      ;;
	     --convert)
	         DO_CONVERT=true
	         shift
	         AT="$1"
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
		  -p|--push-from|--pushback)
			  DO_EXPAND=true
			  shift
			  EXPANSION_DIR="$1"
			;;
		   --excluding)
			  shift
			  EXCLUDE="$1"
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
		 # `` 
	     -v|--verbose)
	        VERBOSE=true
	      ;;
	     -h|--help)
	        usage 0
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
	[ ! -z $DO_UNINSTALL ] && init --uninstall
	
	
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
		[ ! -d "$CACHE_DIR" ] && mkdir -pv $CACHE_DIR/tmp
	
		# Update the configuration file and move the old data. 
		[ -f "$CACHE_CONFIG" ] && {
			# First, keep a record of the old directory.
			OLD_CACHE_DIR=`sed -n '/^CACHE_DIR=/p' $CACHE_CONFIG | sed "s/^CACHE_DIR=//"`
	
			# Move the old data to the new directory.
			# [ -d "$OLD_CACHE_DIR" ] && {
			[ -d "$OLD_CACHE_DIR" ] && [[ ! "$OLD_CACHE_DIR" == "$CACHE_DIR" ]] && {
				mv -v $OLD_CACHE_DIR/* $CACHE_DIR
				mv -v $OLD_CACHE_DIR/.CACHE_DB $CACHE_DIR/.CACHE_DB
				rmdir -pv $OLD_CACHE_DIR 2>/dev/null  # Only removes empty dirs...
			}

			# Always touch.
			touch $CACHE_DIR/.CACHE_DB
	
			# Update the configuration file.
			sed -i "s|^\(CACHE_DIR=\).*|\1$CACHE_DIR|" $CACHE_CONFIG
		}
	}
	
	
	# Generate a configuration file.
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
IS_LIB=$IS_LIB
REMOTE_URL_ROOT=$REMOTE_URL_ROOT
REMOTE_GLOBAL_KEY=$REMOTE_GLOBAL_KEY" > $CACHE_CONFIG
	fi
	
	
	# Grab the CACHE_CONFIG
	source $CACHE_CONFIG
	CACHE_OPTIONS="$CACHE_DIR/.CACHE_OPTIONS"
	
	# Not sure why we have to create a database everytime, but it should be there.
	[ ! -f "$CACHE_DB" ] && touch $CACHE_DB
		
	# Check to use a library name or not.
	[ -z "$IS_LIB" ] && local PROGRAM="cache"
	
	# Create a CACHE options file.  Carries all additional options for cache.
	[ ! -z $DO_ADD_CACHE_OPTIONS ] && {
		# Cache options
		[ ! -f "$CACHE_OPTIONS" ] && touch $CACHE_OPTIONS
	
		# Dump all the cache options supplied.
		save_args -dump args | { FN="`cat /dev/stdin`"; 
			while read line
			do
				[ ! -z "$line" ] && {
					for arg in $(printf "$line\n" | sed "s/,/ /g")
					do
						# If the text is not found, write it.
						[ -z `sed "/${arg}=/p" $CACHE_OPTIONS` ] && {
							printf "${arg}=\n" > /dev/stdout
						}
					done
				}
			done < $FN
		}
	}
	
	
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
		ls --group-directories-first --color $CACHE_DIR/$FOLDER
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
	
	
	# exists
	[ ! -z $DO_EXISTS ] && not_exists $BLOB
	
	
	# create
	[ ! -z $DO_CREATE ] || [ ! -z "$DO_CONVERT" ] && {
		# Title and summary are always required.
		[ -z "$SUMMARY" ] && {
			error -p "$PROGRAM" -e 1 -m "No summary specified."
		}
	
		# If converting,move through a couple of additional checks.
		[ ! -z "$DO_CONVERT" ] && {
			# Make sure that $AT is a file (and not something else)
			[ -z "$AT" ] && error -e 1 -m "No file to convert supplied." -p $PROGRAM
	
			# Files
			[ ! -f "$AT" ] && {
				error -m "File '$AT' either does not exist or is not a file." \
					-e 1 -p $PROGRAM
			}
	
			# If it's got an extension, cut it and use it as the name?
			# The -b option can supply a name in this case.
			if [ -z "$BLOB" ]
			then
				NAME=`basename ${AT}`
				NAME=${NAME%.*}		# Should alwyas just cut the extension.
				BLOB="$NAME"
			else
				NAME="$BLOB"
			fi
		}
	
		# Check for a valid name. 
		exists ${NAME:-$BLOB}
	
		# Get some defaults.
		UUID=`rand`
		TITLE=${NAME:-$BLOB}
#echo $TITLE
#read
		# Handle folder names.
		case "$FORMAT" in 
			DATESTAMP) 	FORMAT="$(date +%F).$(date +%s)";;
			UUID) 		FORMAT="`rand | head -c 20`";;
			# CUSTOM) FORMAT="$(date +%F).$(date +%s)" ;;
		esac
	
		# Common vars and files.
		FOLDER="$CACHE_DIR/${TITLE}.${FORMAT}"
		DEPENDENCIES="$FOLDER/DEPENDENCIES"
		MANIFEST="$FOLDER/MANIFEST"
		VERSIONS="$FOLDER/VERSIONS"
		INSTALL="$FOLDER/INSTALL"
		README="$FOLDER/README.md"
		GITIGNORE="$FOLDER/.gitignore"
		LINKIGNORE="$FOLDER/.linkignore"
	
		FILE_ARR=("$FOLDER"	"$DEPENDENCIES" "$MANIFEST" "$VERSIONS" "$INSTALL" "$README" "$GITIGNORE" "$LINKIGNORE")
	
		DIR_ARR=( "$FOLDER/src" "$FOLDER/tests" "$FOLDER/docs" )
	
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
AUTHORS=$AUTHORS"
		} > $MANIFEST
	
		# Do not track VERSION by default.
		printf "VERSIONS\n" >> $GITIGNORE
		
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
	
		# Keep source or not?
		[ ! -z $DO_CONVERT ] && cp -v $AT $FOLDER 
	
		# Finally, start with the version control madness.
		#echo "Initializing Git repository for $BLOB..."
		cd $FOLDER
		git init
		git add .
		git commit -m "cache_$CURRENT_VERSION committed on `date`"
		[ ! -z $USE_BRANCHES ] && { 
			printf '' > /dev/null
			# git branch "$CURRENT_VERSION"		
			# [ -z `git branch | grep -v 'master'` ] && error -m "Not able to track '$BLOB' repository." -p "$PROGRAM"
		}	
		# echo "Repository creation successful."
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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

	# Adding changes and files?
	[ ! -z $DO_EXPAND ] && {
		# Both an applicaiton and expansion directory should be supplied.
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
		[ -z "$EXPANSION_DIR" ] && {
			error -e 1 -m "No directory specified." -p "$PROGRAM"
		}

		# Expansion 
		[ -z "$EXPANSION_DIR" ] && {
			error -e 1 -m "No directory specified." -p "$PROGRAM"
		}
	
		# Find entry.
		FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"
	
		# Is it there?
		not_exists $BLOB

		# Finally, check that the directory is a real one...
		EXPANSION_DIR=`get_fullpath $EXPANSION_DIR`
		[ ! -d "$EXPANSION_DIR" ] && {
			error -e 1 -m "Directory '$EXPANSION_DIR' does not exist." -p $PROGRAM
		}

		# Scan the directory and do stuff.
		SCANDIR_LEVEL=0
		scan_and_link() {
			[ -z "$1" ] && error \
				-m "Argument to scan_and_link() should not be blank.\n" \
				-p "DEVELOPER" -e 1

			for UNIX_FILE in $(ls --group-directories-first "$1")
			do
				if (( $SCANDIR_LEVEL < $ARR_DEPTH ))
				then
					UNIX_FILE="$1/$UNIX_FILE"
					CHECK_FILE="${FOLDER}${UNIX_FILE##${EXPANSION_DIR}}"
					# echo Folder $FOLDER
					# echo Dir $EXPANSION_DIR
					# echo Basefile: "${FOLDER}${UNIX_FILE##${EXPANSION_DIR}}"

					# Directory 
					if [ -d "$UNIX_FILE" ]
					then
						# echo "$UNIX_FILE is a directory."
						[ ! -d "$CHECK_FILE" ] && mkdir -pv $CHECK_FILE
						SCANDIR_LEVEL=$(( $SCANDIR_LEVEL + 1 ))
						scan_and_link "$UNIX_FILE"

					# Link
					elif [ -L "$UNIX_FILE" ]
					then
						# Check if the link is valid.
						# readlink -f $UNIX_FILE

						# Then link to that file's source.
						[ ! -L "$CHECK_FILE" ] && ln -sv $UNIX_FILE $CHECK_FILE
						# echo "$UNIX_FILE is a symbolic link."

					# Regular File
					elif [ -f "$UNIX_FILE" ]
					then
						# Check if the file already exists in the source dir and
						# is a hard link.
						# echo $(get_inode $UNIX_FILE) $(get_inode $CHECK_FILE)

						# File is not there, let's link it. 
						if [ ! -f "$CHECK_FILE" ] 
						then
							# echo "$UNIX_FILE has yet to be linked."
							ln -v $UNIX_FILE $CHECK_FILE
						# File is there, but not linked for whatever reason.
						elif [ ! $(get_inode $UNIX_FILE) -eq $(get_inode $CHECK_FILE) ]
						then
							# May want to diff these first...
							# Or check their last updated times.
							rm -fv $CHECK_FILE
							ln -v $UNIX_FILE $CHECK_FILE
						fi	

						# Hard link it if it does not exist (dependent on how
						# you want to maintain the file too...)
						# echo "$UNIX_FILE is a file."

					# Device files, and other ridiculous shit...
					else
						[ -z $VERBOSE ] && {
							{
								printf "$UNIX_FILE is neither a regular file "
								printf "nor a directory.\n" 
							} >> /dev/stderr
						}
					fi
				else
					error \
						-m "The directory structure is too deep for the limit imposed." \
						-p "$PROGRAM" -e 1
					exit 1
				fi
			done
		}

		# Run this
		scan_and_link "$EXPANSION_DIR"
		# unset UNIX_FILE CHECK_FILE SCANDIR_LEVEL
		UNIX_FILE= CHECK_FILE= SCANDIR_LEVEL=0
	}
	
	
	# Commit
	# Adds named branch corresponding to the version, 
	# stashing any unsaved changes.
	[ ! -z $DO_COMMIT ] && {
		# Anything given?
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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

		# Create a new branch with changes.
		cd $FOLDER
		git add .
		# How to handle these errors when switching branches?
		[ -z "`git branch | sed -n '/* master/p'`" ] && git checkout master

		# Check that you're on the master branch.
		[ ! -z $USE_BRANCHES ] && { 
			git branch $CURRENT_VERSION
			git checkout $CURRENT_VERSION
		}

		# Make a commit and go back.
		git commit -m "cache $CURRENT_VERSION - `date`"
		# git checkout master - only if not on master...
		cd $CURRENT_PATH

		# Merge the top (or a different branch) with the master branch.
		[ ! -z $USE_BRANCHES ] && [ ! -z "$DO_MERGE_MASTER" ] && {
			git merge `awk -F '|' '{ print $2 }' $VERSIONS | tail -n 1`
		}
	}
	
	
	# Interpret a MANIFEST document. 
	[ ! -z $DO_INTERPRET ] && {
		# Anything given?
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
		[ -z "$DVAR" ] && error -e 1 -m "No dependencies specified." -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
		[ -z "$DVAR" ] && error -e 1 -m "No dependencies specified." -p "$PROGRAM"
	
		# Is it there?
		not_exists $BLOB
	
		# Define the manifest
		DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
		[ ! -f $DEPENDENCIES ] && error -e 1 -m "No file found for dependency tracking.\nPerhaps this file had no dependencies?\n" -p "$PROGRAM"
	
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
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
	
		# Find entry.
		FOLDER=`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
			awk -F ':' '{ print $4 }'`
	
		# Find dependencies
		DEPENDENCIES="$CACHE_DIR/$FOLDER/DEPENDENCIES"
		[ ! -f $DEPENDENCIES ] && error -e 1 -m "No file found for dependency tracking.\nPerhaps this file had no dependencies?\n" -p "$PROGRAM"
	
		# List them out.
		LIST=`cat $DEPENDENCIES | sed '/^$/d'`
		COUNT=`cat $DEPENDENCIES | sed '/^$/d' | wc -l`
	
		# Pretty should be an option.
		[ ! -z $PRETTY ] && {
			if [ $COUNT -gt 1 ] 
			then 
				printf "$COUNT dependencies found for '$BLOB':\n"
			elif [ $COUNT -eq 1 ]
			then 
				printf "$COUNT dependency found for '$BLOB':\n"
			fi
		}

		# Show the list.
		cat $DEPENDENCIES | sed '/^$/d' | awk -F '|' '{ print $1 }' 
	}
	
	
	# Freeze
	[ ! -z $DO_FREEZE ] && { 
	  	# Make sure an application and freeze directory has been specified.
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
		[ -z "$FREEZE_AT" ] && error -e 1 -m "No directory to freeze." -p "$PROGRAM"
	
		# Check the application's existence.
		not_exists $BLOB
	
		# Choose the directory where the application is. 
		FOLDER="$CACHE_DIR/$(grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | awk -F ':' '{ print $4 }')"
	
		# Do a find on the directory where the file is?
		FREEZE_AT="`get_fullpath $FREEZE_AT`"

		echo $FOLDER
		echo $FREEZE_AT

		# Freeze what's in the folder currently.
		# rm -rf $FREEZE_AT/*
		# cp -rv $FOLDER/* $FREEZE_AT
		SCANDIR_LEVEL=0
		scan_and_freeze() {
			[ -z "$1" ] && error \
				-m "Argument to scan_and_freeze() should not be blank.\n" \
				-p "DEVELOPER" -e 1

			for UNIX_FILE in $(ls --group-directories-first "$1")
			do
				if (( $SCANDIR_LEVEL < $ARR_DEPTH ))
				then
					UNIX_FILE="$1/$UNIX_FILE"
					CHECK_FILE="${FOLDER}${UNIX_FILE##${FREEZE_AT}}"

					# Link
					if [ -L "$UNIX_FILE" ]
					then
						# Check if the link is valid.
						TMP_FREEZE="`readlink -f $UNIX_FILE`"
						
						# Copy whatever the original file is, destroying the link.
						if [ -d "$TMP_FREEZE" ] 
						then 
							rm -rfv $UNIX_FILE  
							mkdir $UNIX_FILE
							cp -rv $TMP_FREEZE $UNIX_FILE
						elif [ -f "$TMP_FREEZE" ]
						then
							rm -fv $UNIX_FILE
							touch $UNIX_FILE
							cat $TMP_FREEZE > $UNIX_FILE
						fi	

					# Directory 
					elif [ -d "$UNIX_FILE" ]
					then
						SCANDIR_LEVEL=$(( $SCANDIR_LEVEL + 1 ))
						scan_and_freeze "$UNIX_FILE"

					# Regular File
					elif [ -f "$UNIX_FILE" ]
					then
						# File is there and hardlinked.  Make a fresh copy. 
						echo "Current dir file: $(get_inode $UNIX_FILE) $UNIX_FILE"
						echo "Cache dir file:   $(get_inode $CHECK_FILE) $CHECK_FILE"

						if [ -f "$CHECK_FILE" ] && [ $(get_inode $UNIX_FILE) -eq $(get_inode $CHECK_FILE) ]
						then
							# May want to diff first or check last updated times of files.
							rm -fv $UNIX_FILE
							touch $UNIX_FILE
							# echo cp -v $CHECK_FILE $UNIX_FILE 
							cat $CHECK_FILE > $UNIX_FILE 
						fi	
					fi
				else
					error \
						-m "The directory structure is too deep for the limit imposed." \
						-p "$PROGRAM" -e 1
					exit 1
				fi
			done
		}

		# Freeze the directory.
		scan_and_freeze "$FREEZE_AT"
		echo '...'
		UNIX_FILE= CHECK_FILE= SCANDIR_LEVEL=
		# unset UNIX_FILE CHECK_FILE SCANDIR_LEVEL
	}
	
	
	# Link to
	[ ! -z $DO_LINK_TO ] || [ ! -z $DO_SYMLINK_TO ] || [ ! -z $DO_COPY_TO ] && {
	  	# Make sure an application and destination directory has been specified.
		[ -z "$BLOB" ] && error -e 1 -m "No application specified." -p "$PROGRAM"
		[ -z "$LINK_TO" ] && error -e 1 -m "No location specified for linking." -p "$PROGRAM"
		
		# Make sure the main application exists.  
		# Initial folder search will fail if not.
		not_exists "$BLOB"
	
		# Also get the initial folder. 
		SEED_FOLDER="$CACHE_DIR/`grep --line-number "|$BLOB|" $CACHE_DB | sed 's/|/:/g' | \
			awk -F ':' '{ print $4 }'`"
	
		# Save it or die.
		[ -z "$SEED_FOLDER" ] && {
			error -e 1 -m "Cannot find source folder: $SEED_FOLDER for application '$BLOB'"
		}
	
		# If there's a dependency list, loop through each entry 
		# and pull those folders.
		[ -z "$DO_IGNORE_NEEDS" ] && {
			# Define the name of our file.
			DEPENDENCIES="$SEED_FOLDER/DEPENDENCIES"
	
			# Search through all the entries here.
			[ -f "$DEPENDENCIES" ] && [ ! -z "`cat $DEPENDENCIES`" ] &&  {
				# Go through and process the list.
				eat_dependencies $DEPENDENCIES
			}
	
			# Error out depending on choices.
			[ -f "$LACK_DEPS" ] && [ ! -z "`cat $LACK_DEPS`" ] && {
				error -m "Missing the following packages:" -p $PROGRAM
				while read line 
				do
					printf "${line}\n"
				done < $LACK_DEPS
				error -m "Stopping installation of $BLOB." -e 1 -p $PROGRAM
			}
	
		}
	
		# Expand the destination directory if not absolute.
		LINK_TO=`get_fullpath $LINK_TO`
	
		# Error out if the folder exists.
		[ ! -d "$LINK_TO" ] && mkdir -pv "$LINK_TO" 
			#error -e 1 -m "'$LINK_TO' already exists.\nNot relinking." -p "$PROGRAM"
		# }
	
		# Set linking flags.
		[ ! -z $VERBOSE ] && LN_FLAGS="-v" || LN_FLAGS=
		[ ! -z $DO_SYMLINK_TO ] && LN_FLAGS="-s $LN_FLAGS" 
	
		# Save the SEED_FOLDER last.
		save_args -depchain "$BLOB|$SEED_FOLDER"
		echo "Here is our final dependency list."
	
		# Show me what's been selected.
		save_args -dump depchain | {
		FN="`cat /dev/stdin`"
		while read line	
		do
			printf "$line\n" | sed 's/|/\t/'
		done < $FN
		}
	
		# Dump all dependencies and go through and add them in.
		save_args -dump depchain | {
		FN="`cat /dev/stdin`"
		while read line	
		do	
			# Blank lines?
			[ -z "$line" ] && continue
	
			# Run the linking
			BLOB_NAME="`printf ${line} | awk -F '|' '{ print $1 }'`"
			BLOB_ROOT="`printf ${line} | awk -F '|' '{ print $2 }'`"
			NO_LINK="$BLOB_ROOT/.linkignore"
	
			# Change directory and switch to *CURRENT branch 
			# unless not default. 
			cd $BLOB_ROOT
			# git stash?
	
			# If this is the first time something has been added, it's possible
			# that there will be no *CURRENT branch.  So we use *INITIAL instead.
			# Version selection should be done here too.
			[ -z "`git branch | sed -n '/* master/p'`" ] && git checkout master
			#if [ -z "`sed -n '/*CURRENT/p' $BLOB_ROOT/VERSIONS`" ]
			#then
			#	git checkout `sed -n '$p' $BLOB_ROOT/VERSIONS | awk -F '|' '{ print $2 }'`
			#else
			#	git checkout `grep '*CURRENT' $BLOB_ROOT/VERSIONS | awk -F '|' '{ print $2 }'`
			#fi
	
	
			# Copy
			[ ! -z "$DO_COPY_TO" ] && cp -rv $BLOB_ROOT ${LINK_TO}/$BLOB_NAME
	
			# Link while we are on this branch.
			[ ! -z "$DO_LINK_TO" ] && {
				for LINK_FILE in `find $BLOB_ROOT | grep -v '.git'` 
				do
					# Define a relative root, always cutting the trailing slash.
					RELATIVE_ROOT="$BLOB_NAME/$(printf "%s" $LINK_FILE | \
						sed "s#${BLOB_ROOT}##" | sed 's#^/##')"
	
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
	
			# Switch back to 'master'
			# git checkout master
			cd - 
		done < $FN
		}
	}
	
	# Clean up.
	tmp_file -w
	unset TMP_FREEZE UNIX_FILE CHECK_FILE SCANDIR_LEVEL ARCHIVE ARGDUMP ARR_DEPTH ARR_ELEMENTS AT AUTHORS AVAR BINDIR BLOB BLOB_NAME BLOB_ROOT CACHE_CONFIG CACHE_DB CACHE_DIR CACHE_OPTIONS CHANGED_DIR CO COPY_TYPE COUNT CURRENT_FILE_POS CURRENT_PATH CURRENT_VERSION CVAR DEFAULT_VERSION DEPENDENCIES DEP_FOLDER DESCRIPTION DIR_ARR DO_ADD_CACHE_OPTIONS DO_AUTHORS DO_CHANGE_DIR DO_COMMIT DO_COMMIT_MASTER DO_CONVERT DO_COPY_TO DO_CREATE DO_DIST_INFO DO_DUMP_CONTENTS DO_EXISTS DO_EXTRA DO_FOLDER DO_FREEZE DO_GIT_IGNORE DO_IGNORE_NEEDS DO_INSTALL DO_INTERPRET DO_LINK_IGNORE DO_LINK_TO DO_LIST DO_LIST_NEEDS DO_MKDIR DO_NEEDS DO_NO_LONGER_NEEDS DO_PRODUCED_ON DO_REGISTER DO_REMOVE DO_REQUIRED DO_SET_CACHE_DIR DO_SUMMARY DO_SYMLINK_TO DO_TOUCH DO_UNINSTALL DO_UPDATE DO_UUID DO_VERSION DVAR END_OF_FILE ENTRY EVAR EXTRA FILE_ARR FN FOLDER FORMAT FORMAT_CUSTOM FREEZE_AT GIT_ID GITIG GITIGNORE GIVAR INSTALL INSTALL_DIR LINE LINKIG LINKIGNORE LINK_TO LIST LIVAR LN_FLAGS MANIFEST MVAR NAME NAMESPACE NO_LINK NO_MKDIR NO_TOUCH OLD_CACHE_DIR PRODUCED_ON PROGRAM README RELATIVE_ROOT REMOTE_GLOBAL_KEY REMOTE_URL_ROOT REQUIRED SEED_FOLDER SELF STATUS SUMMARY SVAR TITLE TVAR URL UUID VALUE VERBOSE VERSION_NAME VERSIONS
}
