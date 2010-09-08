#!/usr/bin/perl

###############################################################################
###
### Subversion Server MIRROR Repository START-COMMIT Hook
### -----------------------------------------------------
###
### $URL$
### $Rev$
###
### This file accompanies Rob Hubbard's Subversion Configuration Suite
###
### @ 2010, Rob Hubbard, based on SVN documentation example.
###
###############################################################################

use strict;

### Parameters

#my $repos = $ARGV[0];
my $user = $ARGV[1];
#my $capabilities = $ARGV[2];

### Result

my $return = 0;

### ===========================================================================
### Start

unless ($user eq "syncuser")
{
	$return = 1;
	print STDERR "This is a MIRROR Repository;\n"
	print STDERR "user commits are prohibited.\n"
}

### ===========================================================================
### Finish

exit $return;
