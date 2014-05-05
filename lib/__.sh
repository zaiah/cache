#!/bin/bash
_usage() {
   STATUS="${1:-0}"
   echo "Usage: ./$LIBPROGRAM
	[ -  ]

-r | --recompile              desc
-w | --with <arg>             desc
-w | --without <arg>          desc
-v | --version                desc
-s | --single-file            desc
-v | --verbose                Be verbose in output.
-h | --help                   Show this help and quit.
"
   exit $STATUS
}
	
[ -z "$#" ] && printf "Nothing to do" > /dev/stderr && _usage 1
__LIBSRC__="$(dirname $(readlink -f $0))/lib"

# Hold library names and checksums.
LIBS=(
  "check_for_editor.sh"
  "error.sh"
  "eval_flags.sh"
  "init.sh"
  "random.sh"
  "tmp_file.sh"
)

# Load each library.
for __MY_LIB__ in ${LIBS[@]}
do
	source "$__LIBSRC__/$__MY_LIB__"
done
