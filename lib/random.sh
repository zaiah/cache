#-----------------------------------------------------#
# random
#
# Generates random byte sequences.
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
random() {
	LIBPROGRAM="random"
	local LENGTH=
	local DEVICE=
	local RANDWORD=
	local DO_INTEGERS=
	local DO_ALPHA=
	local DO_OMIT=
	local OMIT=
	local DO_URL_SAFE=
	local DO_FILENAME_SAFE=
	local REPLACEMENT=
	local VERBOSE=
	
	# random_usage - Show usage message and die with $STATUS
	random_usage() {
	   STATUS="${1:-0}"
	   echo "Usage: ./$LIBPROGRAM
		[ -  ]
	
	-l | --length <arg>           Return <arg> amount of characters. 
	-f | --filename-safe          Return a random string safe to use as a 
	                              filename. 
	-u | --url-safe <arg>         Return a URL-safe string. 
	-i | --integers               Return only integers. 
	-a | --alpha                  Return only letters. 
	-o | --omit <arg>             Omit certain characters. 
	-v | --verbose                Be verbose in output.
	-h | --help                   Show this help and quit.
	"
	   exit $STATUS
	}
	
	
	# Die if no arguments received.
	[ -z "$#" ] && printf "Nothing to do\n" > /dev/stderr && random_usage 1
	
	# Process options.
	while [ $# -gt 0 ]
	do
	   case "$1" in
	     -d|--device)
	         shift
	         DEVICE="$1"
	      ;;
	     -l|--length)
	         shift
	         LENGTH="$1"
	      ;;
	     -i|--integers)
	         DO_INTEGERS=true
	      ;;
	     -a|--alpha)
	         DO_ALPHA=true
	      ;;
	     -o|--omit)
	         DO_OMIT=true
	         shift
	         OMIT="$1"
	      ;;
	     -u|--url-safe)
	         DO_URL_SAFE=true
	      ;;
	     -f|--filename-safe)
	         DO_FILENAME_SAFE=true
	      ;;
	     -r|--replacement)
	         shift
	         REPLACEMENT="$1"
	      ;;
	     -v|--verbose)
	        VERBOSE=true
	      ;;
	     -h|--help)
	        random_usage 0
	      ;;
	     --) break;;
	     -*)
	      printf "Unknown argument received.\n" > /dev/stderr;
	      random_usage 1 ;;
	     *) break;;
	   esac
	shift
	done

	# For the brave that write their own devices.
	DEVICE="${DEVICE:-"/dev/urandom"}"

	# Do a quick filename check.
	[ ! -c "$DEVICE" ] && {
		{ 
			printf "Device $DEVICE not found on this system.\n"
			printf "Exiting..."
		} > /dev/stderr
		exit 1
	}

	# Also check for base64
	[ -z "$(which base64 2>/dev/null)" ] && {
		{ 
			printf "base64 program not found on this system.\n"
			printf "Exiting..."
		} > /dev/stderr
		exit 1
	}
	
	# Set length 
	LENGTH="${LENGTH-30}"
	REPLACEMENT="${REPLACEMENT:-"_"}"
	
	# Replacement can't have a space.
#	[ ! -z "$REPLACEMENT" ] && [[ "$REPLACEMENT" =~ " " ]] && {
#	}

	# Run it.
	# INTGEGERS and ALPHA should use a more efficient algorithim.
	# integers
#	[ ! -z $DO_INTEGERS ] && {
#	   printf '' > /dev/null
#		RANDWORD=$(printf $RANDWORD | sed 's#/#_#g')
#	}
#	
#	# alpha
#	[ ! -z $DO_ALPHA ] && {
#	   printf '' > /dev/null
#		RANDWORD=$(printf $RANDWORD | sed 's#/#_#g')
#	}
	RANDWORD="$(head -c $LENGTH $DEVICE | base64 --wrap=0 | sed 's/\n//g')"
	
	# filename_safe
	[ ! -z $DO_FILENAME_SAFE ] && {
		RANDWORD=$(printf $RANDWORD | sed 's#/#_#g')
	}
	
	# omit
	[ ! -z $DO_OMIT ] && {
#		for n in `chop $OMIT`; do
		RANDWORD=$(printf $RANDWORD | sed 's#/#_#g')
#		done
	}
	
	# url
	[ ! -z $DO_URL_SAFE ] && {
#		for n in <url unsafe chars>
	   printf '' > /dev/null
# 		done
	}

	# Return the processed stream.
	printf -- "%s\n" "$RANDWORD" 
}
