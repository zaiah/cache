
#	  --test)
#		  shift
#		  case "$1" in 
#			  args) TEST=args;;
#			  deps) TEST=deps;;
#			  gi) TEST=gi;;
#			  li) TEST=li;;
#			  ex) TEST=ex;;
#	     esac
#		  save_args -dump $TEST | { 
#				FN=`cat /dev/stdin`
#				while read line 
#				do
#					[ ! -z "$line" ] && echo $line
#				done < $FN
#		  }
#		  exit
#		;;
#	  --reset)
#		  	source $BINDIR/.CACHE
#			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
#			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
#			exit
#		;;
#	  --total-reset)
#		  	source $BINDIR/.CACHE
#			init --uninstall
#			[ -d "$CACHE_DIR" ] && rm -rfv $CACHE_DIR
#			[ -f "$BINDIR/.CACHE" ] && rm -v $BINDIR/.CACHE
#			exit
#		;;
