#!/bin/bash

###############################################################################
###
### `Find and Grep` for Working Copies
### ----------------------------------
###
### $URL$
### $Rev$
###
### This file accompanies Rob Hubbard's Subversion Configuration Suite
###
### @ 2010, Rob Hubbard.
###
###############################################################################

### Find + Grep - .svn

### $1 = start directory
### $2 = file glob
### $3 = string pattern

if [ "$3" == "" ] ; then
	echo "working-copy find and grep"
	echo "syntax: ./wc_find_grep \${start_dir} \${file_glob} \${string_pattern}"
else
	find "$1" -regextype posix-extended \
		-regex ".*(\.svn)" \
		-prune -or \
		-iname "$2" \
		-exec grep --with-filename --line-number "$3" \{\} \;
fi

