#------------------------------------------------------
# get_fullpath.sh 
# 
# Evaluates the full file path of some directory.
#-----------------------------------------------------#
function get_fullpath() {
	# Must have uname
	local uname=
	uname=`which uname 2>/dev/null`

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
			readlink -f "$1" 

		# Cygwin and Mac OSX will require another method.
		elif [[ "$osname" =~ "CYGWIN" ]] || [[ "$osname" =~ "DARWIN" ]]
		then

			# Check for current directory first.	
			if [[ "${1:0:1}" == "." ]] && [[ -z "${1:1:1}" ]] 
			then 
				printf "%s" "`pwd`"	

			# Then check for things relative to it.
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
		fi	
	fi	
	unset uname
}
