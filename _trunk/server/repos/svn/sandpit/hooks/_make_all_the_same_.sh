#!/bin/bash

### $URL$
### $Rev$

### ===========================================================================

function do_cp
{
	# $1 = destination name

	if [ "$1" == "" ]
	then
		echo "error $0 / do_cp : missing parameter"
	else
		#fn="$1"
		fn="$1.sh"
		if [ -e "$fn" ]
		then
			echo "overwriting $fn ..."
			cp "_hook_template_.sh.tmpl" "$fn"
		else
			echo "no $fn to overwrite"
		fi
	fi
}

### ===========================================================================

do_cp "start-commit"
do_cp "pre-commit"
do_cp "post-commit"

do_cp "pre-revprop-change"
do_cp "post-revprop-change"

do_cp
do_cp "blibble"
