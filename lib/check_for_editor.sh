#-----------------------------------------------------#
# check_for_editor
#
# Checks for the presence of one of many popular text
# editors and makes a choice.
#-----------------------------------------------------#
check_for_editor() {
	# declare -a __ED_LIST__
	# __ED_LIST__=( "vim", "vi", "emacs", "joe", "nano", "ed" )
 
	declare -a __ED_LIST__
	__ED_LIST__=(
		"/bin/vim" "/usr/bin/vim" "/usr/local/bin/vim" 
		"/bin/vi" "/usr/bin/vi" "/usr/local/bin/vi"  			# Vim
		"/bin/emacs" "/usr/bin/emacs" "/usr/local/bin/emacs"	# Emacs
		"/bin/joe" "/usr/bin/joe" "/usr/local/bin/joe" 	   	# Joe
		"/bin/nano" "/usr/bin/nano" "/usr/local/bin/nano" 		# nano
		"/bin/ed" "/usr/bin/ed" "/usr/local/bin/ed" 		   	# ed
	)

	for __ED__ in ${__ED_LIST__[@]}
	do
		[ -f "$__ED__" ] && [ -x "$__ED__" ] && EDITOR="$__ED__" && break
	done

	echo $EDITOR
}
