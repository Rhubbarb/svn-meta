#!/bin/bash

###############################################################################
###
### `Find` for Working Copies
### -------------------------
###
### $URL$
### $Rev$
###
### This file accompanies Rob Hubbard's Subversion Configuration Suite
###
### @ 2010, Rob Hubbard.
###
###############################################################################

### Find - .svn

### $1 = start directory
### $2 = file glob
### $3 = string pattern

if [ "$2" == "" ] ; then
	echo "working-copy find"
	echo "syntax: ./wc_find \${start_dir} \${file_glob}"
else
	find "$1" -regextype posix-extended \
		-regex ".*(\.svn)" \
		-prune -or \
		-iname "$2" \
		-print
fi

