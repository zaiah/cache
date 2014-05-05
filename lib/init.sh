#-----------------------------------------------------#
# init 
#
# Generates a settings file for programs.
# 
# --load - Load a variable.
# --get  - Show me the value of a variable
# --update 
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
init() {
	# Local variables
	local BINDIR=
	local USERS=
	local USERS_GROUP=
	local D=
	local DEP=
	local DEP_FAIL=
	local DEP_FALSE=
	local DEPLOY_DEFAULT=
	local DEPLOYMENT_DIRECTORY=
	local DEPLOY_PRIMARY=
	local DEPLOY_RELATIVE=
	local DO_ADD=
	local DO_CONFIG=
	local DO_DEFUALTS=
	local DO_FILE=
	local DO_FILENAME=
 	local SHOW_DEFAULT_BINARY=
 	local SHOW_DEFAULT_CONFIG=
	local DO_GET=
	local DO_INSTALL=
	local DO_LIST=
	local DO_LOAD=
	local DO_WRITE=
	local DO_APPEND=
	local DO_LOAD_ALL=
	local DO_MISSING_IS_FATAL=
	local DO_MKDIRS=
	local DO_MOVE_SRC=
	local DO_NO_VC_UPDATE=
	local DO_RETURN_FILEPATH=
	local DO_SKIP_MKDIR=
	local DO_UPDATE=
	local GET=
	local ID_LN_FLAGS=
	local ID_MKDIR_FLAGS=
	local INSTALL_AS_LIST=
	local INSTALL_DEFAULT=
	local INSTALL_DIR=
	local INSTALL_DIRECTORY=
	local INSTALL_LIST=
	local LIBPROGRAM=
	local MISSING_IS_FATAL=
	local MKDIR_LIST=
	local OBJ_TO_LOAD=
	local OPDEPS=
	local READLINK_FP=
	local SETTINGS=
	local SETTINGS_FILE=
	local SRC_FILE=
	local STATUS=
	local T=
	local UPDATE_VALUE=
	local LOADED_VALUE=
	local TMP_FILE=
	local uname=
	local osname=
	LIBPROGRAM="init"

	# Retrieve full file path.
	get_fullpath() {
		# Must have uname
		uname=`which uname 2>/dev/null`

		# function for pull path name ness...
		eval_path() {
			# Return current directory if only a dot was specified. 
			if [[ "${1:0:1}" == "." ]] && [[ -z "${1:1:1}" ]] 
			then 
				printf "%s" "`pwd`"	

			# Return the absolute path relevant to the current directory.
			elif [[ "${1:0:1}" == "." ]] && [[ "${1:1:1}" == "/" ]]
			then 
				printf "%s" "$1" | sed "s|.|`pwd`|"

			# Return directory paths that are above yours. 
			elif [[ "${1:0:2}" == ".." ]]
			then 
				# Keep going forward until you find other paths.
				printf "%s" "$(pwd)/$1"	

			# Evaluate any names in the current directory.
			elif [[ ! "${1:0:1}" == "/" ]]
			then 
				printf "%s" "$(pwd)/$1"	
		
			# ...
			else	
				printf "%s" $1 
			fi
		}

		# Return nothing without `uname`.
		if [ -z "$uname" ] 
		then
			printf "%s" ""
	
		# Evaluate OS. 
		else
			osname=`$uname | tr '[a-z]' '[A-Z]'`

			# If name contains linux, then use readlink -f
			if [[ "$osname" =~ "LINUX" ]]
			then
				# Handle a symbolic link more effectively.
				READLINK_FP=`readlink -f $1`
				[ ! -z "$READLINK_FP" ] && readlink -f $1 || eval_path "$1"
					
			# Cygwin and Mac OSX will require another method.
			elif [[ "$osname" =~ "CYGWIN" ]] || [[ "$osname" =~ "DARWIN" ]]
			then
				eval_path "$1"
			fi	
		fi	
		unset uname
	}

	# Chops a string up by some delimiter.
	chop() {
		local D=
		local T=
		if [[ $1 == "-d" ]]; then 
			D="$2" 
			T="$3"
		else
			D=","
			T="$1"
		fi
		mylist=(`printf "$T" | sed "s/$D/ /g"`)
		echo "${mylist[@]}"		# Return the list all ghetto-style.

		unset D
		unset T
		unset mylist
	}

	# init_usage - Show usage message and die with $STATUS
	init_usage() {
	   STATUS="${1:-0}"
	   echo "Usage: ./$LIBPROGRAM

	Summary: Creates a file called INIT with a bunch of settings.

	Variable manipulation:
	-o | --load <arg>             Load an item <arg> so that it can be used, 
	                              but do not show the value. 
	-g | --get <arg>              Load item <arg> and display its value. 
	-u | --update <arg>           Update an item <arg>. 
	-w | --with <arg>             To be used in concert with --update.
	     --load-all               Source the init file.
	-l | --list                   Just show all variables in INIT.

	Initial run nonsense:
	-x | --fatal-if-missing <arg> Die if any programs in <arg> are not within 
	                              the current \$PATH.
	-d | --deploy-to              Override the default directory, if desired. 
	     --deploy-relative        Deploy relative to /usr/local/etc
	-k | --mkdir                  Make any needed directories at <config>.
                                 use this flag to make the directory. 
	-m | --move-source            Move the source code somewhere else.
	-i | --install                Install file or list of files to a directory
											within the current PATH (/usr/local/bin).
	     --install-to <dir>       Install a file to some other directory
		                           besides /usr/local/bin.
		  --install-as <name=val>  Install a file as a link with a different 
		                           name.
	-u | --uninstall              Uninstall any executable links.
	     --uninstall-files        Uninstall any program files.

	General stuff:
	-dc | --default-config        Show the file path of this init file. 
	-db | --default-binary        Show the file path where this binary goes.
	-f | --file                   Show the file path of this init file. 
	-h | --help                   Show this help and quit.
	"
	   exit $STATUS
	}
	
	
	# Die if no arguments received.
	[ -z "$#" ] && {
		printf "Nothing to do\n" > /dev/stderr 
		settings_usage 1
	}
	
	# Process options.
	while [ $# -gt 0 ]
	do
	   case "$1" in
			# Load configuration
	     -o|--load)
	         DO_LOAD=true
				shift
				LOADEE="$1"
	      ;;
	
			# Write stuff to file.
	     -a|--append)
	         DO_APPEND=true
				shift
				ADDITION="$1"
	      ;;

			# Write will blow away anything that may be there.
	     --write)
	         DO_WRITE=true
				shift
				ADDITION="$1"
	      ;;

	     --load-all)
	         DO_LOAD_ALL=true
	      ;;

			# Get a particular setting out.
	     -g|--get)
	         DO_GET=true
	         shift
	         GET="$1"
	      ;;

	     -u|--update)
	         DO_UPDATE=true
				shift
				UPDATEE="$1"
	      ;; 

	     -w|--with)
			  	shift
				UPDATE_VALUE="$1"
	      ;; 

	     -l|--list)
	         DO_LIST=true
	      ;;

			# Check for dependencies.
	     -x|--fatal-if-missing)
	         DO_MISSING_IS_FATAL=true
	         shift
	         MISSING_IS_FATAL="$1"
	      ;;

	     -d|--deploy-to)
	         shift
	         DEPLOY_PRIMARY="$1"
	      ;;

	     -e|--deploy-relative)
	         shift
	         DEPLOY_RELATIVE="$1"
	      ;;

			# Makes any important directories.
	     -k|--mkdir)
	         DO_MKDIRS=true
				shift
				MKDIR_LIST="$1"
	      ;;

			# Makes any important directories.
	     -i|--install)
	         DO_INSTALL=true
				shift
				INSTALL_LIST="$1"
	      ;;

			# Move the source when installing.
	     -m|--move-source)
	         DO_MOVE_SRC=true
	      ;;

			# Makes any important directories.
	     --install-to)
				shift
				INSTALL_DIR="$1"
	      ;;		

			# Install as
	     --install-as)
				shift
				INSTALL_AS_LIST="$1"
	      ;;		

			# Uninstall 
	     --uninstall)
				DO_UNINSTALL=true
		  ;;

			# Uninstall 
	     --uninstall-files)
				DO_UNINSTALL_FILES=true
		  ;;
			
			# Return the file path.  For generating stuff.
	      -f|--file)
	         DO_RETURN_FILEPATH=true
	      ;; 

			# No version contorl file update.
	     --no-vc-update)
	         DO_NO_VC_UPDATE=true
	      ;; 

			# No defaults.
	     --no-default)
	         NO_DEFAULTS=true
	      ;; 
		
		  -dc|--default-config)
			  SHOW_DEFAULT_CONFIG=true
			;;

	     -db|--default-binary)
			  SHOW_DEFAULT_BINARY=true
			;;

	     -h|--help)
	        init_usage 0 | sed 's/^[\t].*//'
	      ;;
	     --) break;;
	     -*)
	      printf "Unknown argument received: $1\n" > /dev/stderr;
	      init_usage 1 | sed 's/^\t//'
	     ;;
	     *) break;;
	   esac
	shift
	done

	# This is VERY confusing.
	# One could leave the source whereever it was cloned OR
	# It could be copied to your real directory (under like
	# /src or something)
	# Handling installs here is smarter...
	# Check for a BINDIR
	if [ -z "$BINDIR" ] || [ ! -d "$BINDIR" ]
	then
		# BINDIR
		BINDIR="$( dirname $(readlink -f $0) )"
#		[[ "$BINDIR" == "lib" ]] && BINDIR="`get_fullpath $BINDIR/..`"
	# Go one step up above lib.
	fi

	# Define one anyway.
	[[ "`basename $BINDIR`" == "lib" ]] && { 
		BINDIR="`get_fullpath $(dirname $BINDIR)`"
	}

	# Static settings.
	SETTINGS_FILE="$BINDIR/.INIT"
	DEPLOY_DEFAULT="/usr/local/etc"
	INSTALL_DEFAULT="/usr/local/bin"
	DPREFIX="# Deployed:"
	IPREFIX="# Installed:"

	# 
 	[ ! -z $SHOW_DEFAULT_BINARY ] && printf "$DEPLOY_DEFAULT"
 	[ ! -z $SHOW_DEFAULT_CONFIG ] && printf "$INSTALL_DEFAULT"

	# Write to SETTINGS_FILE, discarding anything previous.
	[ ! -z $DO_WRITE ] && printf "${ADDITION}\n" > $SETTINGS_FILE

	# Append anything to your SETTINGS_FILE
	[ ! -z $DO_APPEND ] && printf "${ADDITION}\n" >> $SETTINGS_FILE

	# Return the filepath only.
	[ ! -z $DO_RETURN_FILEPATH ] && {
		printf "%s\n" $SETTINGS_FILE
	}

	# list 
	[ ! -z $DO_LIST ] && {
		cat $SETTINGS_FILE | {
		awk -F '=' '
		# j(l) 
		# Limits output of argument [l] to 30 characters, 
		# using spaces to pad any output not there.
		function j(l) { 
			for ( i = 1; i < ( 30 - length(l) + 1 ); ++i ) printf("%s"," ")
		}

		{ if ( length($1) > 1 ) print $1 ": " j($1), $2 }'
		}	
	}

	# load
	[ ! -z $DO_LOAD_ALL ] && source $SETTINGS_FILE

	# Load into memory.  There seems to be no non-dangerous way to do this.
	[ ! -z $DO_LOAD ] && {
		# /tmp may not always be a suitable place to write....
		TMP_FILE="/tmp/.$(( $RANDOM * `date +%s` )).${LIBPROGRAM}"
		LOADED_VALUE="`sed -n "/^${LOADEE}=/p" $SETTINGS_FILE`"
		[ ! -z "$LOADED_VALUE" ] && {
			printf -- "%s\n" "$LOADED_VALUE" > $TMP_FILE 
			source $TMP_FILE
			rm -f $TMP_FILE
		}
	}

	# get
	# A good reason to use snake_case or something else...
	[ ! -z $DO_GET ] && {
		# Show value of the var asked for.
		sed -n "s/^${UPDATEE}=//p" $SETTINGS_FILE
	}

	# Run an update.
	[ ! -z $DO_UPDATE ] && {
		# Find exact line.
		if [ ! -z "`sed -n "/^${UPDATEE}=/p" $SETTINGS_FILE`" ] 
		then
			# Run a permanent replacement with sed.
			sed -i "s/^\(${UPDATEE}=\).*/\1\"${UPDATE_VALUE}\"/" $SETTINGS_FILE

		# Just append it otherwise.
		else
			printf -- "%s\n" "${UPDATEE}=\"${UPDATE_VALUE}\""  >> $SETTINGS_FILE
		fi
	}

	# missing_is_fatal - checks for missing dependencies.
	[ ! -z $DO_MISSING_IS_FATAL ] && {
		for DEP in $(chop ${MISSING_IS_FATAL[@]})
		do
			# Is this optional?
			if [[ "$DEP" =~ ':' ]] 
			then
				OPDEPS=( `chop -d ':' $DEP` )
				DEP_FALSE=

				# Move through each optional dependency.
				for OPDEP in ${OPDEPS[@]} 
				do
					[ -z "`which $OPDEP	2>/dev/null`" ] && {
						printf -- "%s\n" "Dependency \"$OPDEP\" not in PATH." > /dev/stderr
						[ -z $DEP_FALSE ] && DEP_FALSE=1 || DEP_FALSE=$(( $DEP_FALSE + 1 ))
					}
				done

				# If same number of elements were false, then neither was found.
				[ -z $DEP_FALSE ] && DEP_FALSE=0
				[ $DEP_FALSE -eq ${#OPDEPS[@]} ] && DEP_FAIL=true

				# Debugging
				# echo Dependencies not found: $DEP_FALSE '|' Dependencies to check: ${#OPDEPS[@]} 

				# Die if something failed.
				[ ! -z $DEP_FAIL ] && { 
					printf "Neither of this program's codependents were found.  Exiting...\n" > /dev/stderr 
					exit 1
				}

				#
				unset DEP_FALSE
				unset OPDEPS 
			else	
				# Does the binary exist in $PATH?
				[ -z "`which $DEP	2>/dev/null`" ] && {
					printf -- "%s\n" "Dependency \"$DEP\" not in PATH." > /dev/stderr
					DEP_FAIL=true
				}

				# Die if something failed.
				[ ! -z $DEP_FAIL ] && { 
					printf "Dependencies not found.  Exiting...\n" > /dev/stderr 
					exit 1
				}
			fi
		done
	}

	# deploy
	[ ! -z $DO_MKDIRS ] && {
		# If a user specified a different deployment directory, we can
		# handle that sanely.
		[ ! -z "$DEPLOY_PRIMARY" ] && {
			# If it contains any path stuff, then get the absolute path.
			DEPLOY_PRIMARY="`get_fullpath "$DEPLOY_PRIMARY"`"
		}

		# Deploy relative to $DEPLOY_DEFAULT
		[ ! -z "$DEPLOY_RELATIVE" ] && {
			DEPLOY_PRIMARY="$DEPLOY_DEFAULT/$DEPLOY_RELATIVE"
#			DEPLOY_TEXT=""
		}

		# If no configuration directory was specified, let's check for 
		# one and add it as well.
		[ ! -f $SETTINGS_FILE ] || [[ `sed -n "s/^CONFIG=//p" $SETTINGS_FILE` == "" ]] && {
			printf "CONFIG=$DEPLOY_PRIMARY\n" >> $SETTINGS_FILE
		}

		# Check the permissions of everything else in the directory too.
		USERS=`ls -l | sed 1d | awk '{ print $3 }' | uniq`
		USERS_GROUP=`ls -l | sed 1d | awk '{ print $4 }' | uniq`

		# If there's more than one, you'll need to warn the user to 
		# change the permissions on .INIT
		if [ `echo $USERS | wc -l` -gt 1 ]
		then
			printf "The file $SETTINGS_FILE is needed for this program\n"
			printf "to operate correctly.\n"
			printf "Please change its permissions manually with sudo, as\n"
			printf "multiple users appear to have work here.\n"
		else
			chown $USERS:$USERS_GROUP $SETTINGS_FILE
		fi

		# Choose a deployment directory or the default.
		DEPLOYMENT_DIRECTORY="${DEPLOY_PRIMARY:-$DEPLOY_DEFAULT}"

		# No defaults?
		if [ ! -z $NO_DEFAULTS ] && \
			[[ "$DEPLOY_DIRECTORY" == "$DEPLOY_DEFAULT" ]] 
		then
			printf "No deployment directory specified.\n" > /dev/stderr
			exit 1
		fi	

		# Do you have permissions to write to the top level?
		[ ! -d "$DEPLOYMENT_DIRECTORY" ] && {
			# Make a directory, discarding the error...
			mkdir -pv $DEPLOYMENT_DIRECTORY 2>/dev/null 

			# ... but checking if it actually exists.
			[ ! -d "$DEPLOYMENT_DIRECTORY" ] && {
				{
					printf "Error creating directory '$DEPLOYMENT_DIRECTORY'.\n"
					printf "(Most likely due to incorrect permissions...)\n"
				} > /dev/stderr
				exit 1
			}
		}

		# Set verbosity.
		[ ! -z $VERBOSE ] && ID_MKDIR_FLAGS='-pv' || ID_MKDIR_FLAGS='-p' 	

		# You'll have to repeat this...
		# Create each host directory 
		for LIST_DIR in $(chop ${MKDIR_LIST[@]})
		do
			mkdir $ID_MKDIR_FLAGS "$DEPLOYMENT_DIRECTORY/$LIST_DIR"
		done

		# Mark the deployment directory for total uninstall.
#		printf -- "%s\n" "$DPREFIX $DEPLOYMENT_DIRECTORY " >> $SETTINGS_FILE
#			DEPLOY_TEXT=""
	}

	# Create ignore for different tracking systems unless undesired.
	[ ! -z $DO_INSTALL ] && {
		# Make sure there's something to install.
		[ -z "$INSTALL_LIST" ] && {
			{ 
				printf "$LIBPROGRAM: Must specify something to install.\n"
			} > /dev/stderr
			exit 1
		}

		# Choose an install directory.
		INSTALL_DIRECTORY="${INSTALL_PRIMARY:-$INSTALL_DEFAULT}"

		# No defaults?
		if [ ! -z $NO_DEFAULTS ] && \
			[[ "$INSTALL_DIRECTORY" == "$INSTALL_DEFAULT" ]] 
		then
			printf "No install directory specified.\n" > /dev/stderr
			exit 1
		fi	

		# Create if it does not exist.
		[ ! -d "$INSTALL_DIRECTORY" ] && {
			# Check that it's absolute.
			[[ ! "${INSTALL_DIRECTORY:0:1}" =~ "/" ]] && {
				{ 
					printf "Must use an absolute directory for installation.\n"
				} > /dev/stderr
				exit 1
			}

			# Make a directory, discarding the error...
			mkdir -pv $INSTALL_DIRECTORY 2>/dev/null 

			# But check on your own if it exists.
			[ ! -d "$INSTALL_DIRECTORY" ] && {
				{
					printf "Error creating directory '$INSTALL_DIRECTORY'.\n"
					printf "(Most likely due to incorrect permissions...)\n"
				} > /dev/stderr
				exit 1
			}
		}

		# Set verbosity.
		[ ! -z $VERBOSE ] && ID_LN_FLAGS='-sv' || ID_LN_FLAGS='-s'

		# Install a list of files in the current directory to a good location.
		for LIST_FILE in $(chop ${INSTALL_LIST})
		do
			# Get the full path of this file.
			SRC_FILE="`get_fullpath $LIST_FILE`"
			LINK_FILE="$INSTALL_DIRECTORY/${LIST_FILE%%.sh}"

			# Make links if file exists and there is no link already.
			[ -f "$SRC_FILE" ] && {
				# Print a message.
				if [ -L "$LINK_FILE" ]
				then
					printf "File exists at '$LINK_FILE' already.\n" > /dev/stderr
				else	
					# Make links.
					ln $ID_LN_FLAGS $SRC_FILE $LINK_FILE

					# Add a record for uninstallation later on.
					[ -z "`grep -x "$IPREFIX $LINK_FILE" $SETTINGS_FILE`" ] && {
						printf -- "%s\n" "$IPREFIX $LINK_FILE" >> $SETTINGS_FILE
				}
				fi
			}
		done
	}

	# Uninstall
	[ ! -z $DO_UNINSTALL ] && {
		for n in `grep "$IPREFIX" $SETTINGS_FILE | sed "s/$IPREFIX //" 2>/dev/null`
		do
			[ -f "$n" ] && rm -v $n
		done
	}

	# Uninstall the files. 
	[ ! -z $DO_UNINSTALL_FILES ] && {
		UNINSTALL_DIR=`grep "$DPREFIX" $SETTINGS_FILE | sed "s/$DPREFIX //"`
		echo $UNINSTALL_DIR
		[ -d "$UNINSTALL_DIR" ] && rm -rfv "$UNINSTALL_DIR"
	}

	# Create ignore for different tracking systems unless undesired.
	[ -z $DO_NO_VC_UPDATE ] && [ ! -z $DO_CREATE ] && {
		for VC_FILE in ".gitignore" ".cvsignore" ".hgignore"
		do
			[ -f "$SETTINGS_FILE" ] && [ -f "$BINDIR/$VC_FILE" ] && {
				[ -z "`grep "$SETTINGS_FILE" $BINDIR/$VC_FILE`" ] && {
					printf "%s\n" "$SETTINGS_FILE" >> $BINDIR/$VC_FILE
				}
			}
		done
	}

	# unset...
	unset BINDIR
	unset D
	unset DEP
	unset DEP_FAIL
	unset DEP_FALSE
	unset DEPLOY_DEFAULT
	unset DEPLOYMENT_DIRECTORY
	unset DEPLOY_PRIMARY
	unset DEPLOY_RELATIVE
	unset DO_ADD
	unset DO_CONFIG
	unset DO_DEFUALTS
	unset DO_FILE
	unset DO_FILENAME
	unset DO_GET
	unset DO_INSTALL
	unset DO_LIST
	unset DO_LOAD
	unset DO_LOAD_ALL
	unset DO_MISSING_IS_FATAL
	unset DO_MKDIRS
	unset DO_MOVE_SRC
	unset DO_NO_VC_UPDATE
	unset DO_RETURN_FILEPATH
	unset DO_SKIP_MKDIR
	unset DO_UPDATE
	unset GET
	unset ID_LN_FLAGS
	unset ID_MKDIR_FLAGS
	unset INSTALL_AS_LIST
	unset INSTALL_DEFAULT
	unset INSTALL_DIR
	unset INSTALL_DIRECTORY
	unset INSTALL_LIST
	unset LIBPROGRAM
	unset MISSING_IS_FATAL
	unset MKDIR_LIST
	unset OBJ_TO_LOAD
	unset OPDEPS
	unset READLINK_FP
	unset SETTINGS
	unset SETTINGS_FILE
	unset SRC_FILE
	unset STATUS
	unset T
	unset DO_WRITE
	unset DO_APPEND
	unset UPDATE_VALUE
	unset LOADED_VALUE
 	unset SHOW_DEFAULT_BINARY
 	unset SHOW_DEFAULT_CONFIG
 	unset USERS 
 	unset USERS_GROUP 
}
