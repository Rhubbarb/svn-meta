#!/usr/bin/perl

###############################################################################
###
### Subversion Server MIRROR Repository PRE-REVPROP-CHANGE Hook
### -----------------------------------------------------------
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
#my $revision = $ARGV[1];
my $user = $ARGV[2];
#my $propname = $ARGV[3];
#my $action = $ARGV[4]; ### 'A'dded, 'M'odified, or 'D'eleted
#my @new_value = <STDIN>;
#my $new_value = join ('', @new_value);

### Result

my $return = 0;

### ===========================================================================
### Start

unless ($user eq "syncuser")
{
	$return = 1;
	print STDERR "This is a MIRROR Repository;\n"
	print STDERR "user unversioned revision property changes are prohibited.\n"
}

### ===========================================================================
### Finish

exit $return;
