#!/bin/bash

###############################################################################
###
### Uniform Subversion Server Repository Hook Wrapper
### -------------------------------------------------
###
### $URL$
### $Rev$
###
### This file accompanies Rob Hubbard's Subversion Configuration Suite
###
### @ 2010, Rob Hubbard.
###
###############################################################################

selfbase=${0%.*}; selfbase=${selfbase##*/}

cd "%~0/../../../_common_/hooks" 2> /dev/null || { echo "ERROR: can't cd to <../../_common_/hooks/>" 1>&2 ; exit 1 ; }

. "subroutine/prepare_environment.sh" 2> /dev/null || { echo "ERROR: can't source <subroutine/prepare_environment.sh>" 1>&2 ; exit 1 ; }

if [ ! -e "${selfbase}.pl" ]
then 
	echo "ERROR: can't do perl <${selfbase}.pl>" 1>&2 
	exit 1
fi
perl "${selfbase}.pl" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" || { echo "ERROR: can't perl <${selfbase}.pl>" 1>&2 ; exit 1 ; }
exit $?
