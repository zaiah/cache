#-----------------------------------------------------#
# error
#
# Prints a nifty error message.
#-----------------------------------------------------#
error() {
	# Names and variables.
	local LIBPROGRAM="error"
	local ERR_FILE="/dev/stderr"  # this could be a few other places.	
	local MESSAGE=
	local EXIT_CODE=
	local DO_STDERR=
	local VERBOSE=
	local PREFIX="ERROR:"
	
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
		  -m|--message)
			  shift
			  MESSAGE="$1"
			;;
	     -l|--log)
	         DO_LOG=true
				shift
				ERR_FILE="$1"
	      ;;
	     -e|--exit)
			   DO_EXIT=true
	         shift
				EXIT_CODE="$1"
	      ;;
	     -s|--stderr)
	         DO_STDERR=true
	      ;;
	     -p|--program)
			  shift
	        PREFIX="$1"
	      ;;
	     -v|--verbose)
	        VERBOSE=true
	      ;;
	     -h|--help)
	        error_usage 0
	      ;;
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
	[ ! -z $DO_EXIT ] && {
		exit $EXIT_CODE
	}

	# Unsets
	unset LIBPROGRAM
	unset MESSAGE
	unset EXIT_CODE
	unset DO_STDERR
	unset VERBOSE
}
