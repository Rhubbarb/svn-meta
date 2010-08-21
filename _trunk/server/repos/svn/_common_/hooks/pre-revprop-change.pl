#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository PRE-REVPROP-CHANGE Hook
### ----------------------------------------------------
###
### $URL$
### $Rev$
###
### Copyright © 2010 Rob Hubbard.
###
### This file forms part of Rob Hubbard's Subversion Configuration Suite
### (the "Software").
###
### Permission is hereby granted, free of charge, to any person obtaining a
### copy of the Software and associated documentation files, to deal in the
### Software without restriction, including without limitation the rights to
### use, copy, modify, merge, publish, and/or distribute (free of charge)
### copies of the Software, and to permit persons to whom the Software is
### furnished to do so, subject to the following conditions:
###
### The above copyright notice and this permission notice shall be included in
### all copies or substantial portions of the Software. For clarity, the above
### copyright notice and this permission notice do not apply to any software
### developed using but not incorporating the Software.
###
### The Software is provided "as is", without warranty of any kind, express or
### implied, including but not limited to the warranties of merchantability,
### fitness for a particular purpose and noninfringement. In no event shall the
### authors or copyright holders be liable for any claim, damages or other
### liability, whether in an action of contract, tort or otherwise, arising
### from, out of or in connection with the Software or the use or other
### dealings in the Software.
###
### "Copyleft; All wrongs reversed."
###
###############################################################################

use strict;

### Parameters

my $repos = $ARGV[0];
my $revision = $ARGV[1];
my $user = $ARGV[2];
my $propname = $ARGV[3];
my $action = $ARGV[4]; ### 'A'dded, 'M'odified, or 'D'eleted
my $new_value = <STDIN>;

### Options

my $allow_property_changes = 1; ### prefer not to have script than set this to 0

my $allow_only_log_modification = 1;
my $backup_values = 1;

### Variables

### Result

my $return = ($allow_property_changes ? 0 : 1);
#$return = 2; ### test value

### ===========================================================================
### Class

my $common = common->spawn("pre-revprop-change", $repos);

$common->msg_now_banner(0);
$common->msg_info_log_only("rev=$revision, user=$user, prop=$propname, action=$action");

### ===========================================================================
### Modules to use

use File::Basename;
use File::Path 'make_path';
use File::Spec;
#use Date::Calc;

### ---------------------------------------------------------------------------
### Function definitions

use subroutine::common;

### ===========================================================================
### Get the repository information

#$youngest = `svnlook youngest $repos`;

### ---------------------------------------------------------------------------
### Other...

### ===========================================================================
### Start

### ---------------------------------------------------------------------------
### Check the property being changed

if ($allow_only_log_modification)
{
	my $is_standard = (substr($propname,0,4) eq "svn:");

	if ($propname ne "svn:log" && $is_standard)
	{
		$common->msg_caught("changes to standard property $propname prohibited.", $return);
	}

	if (($action ne "M") && $is_standard)
	{
		$common->msg_caught("property action '$action' prohibited on standard property.", $return);
	}
}

### ---------------------------------------------------------------------------
### Perform a backup of the old value

### store in svn-bak/reposname-bak/prop/rev_prop-name_at_by-user.dat

if ($backup_values && ($return == 0 or $return == 2))
{
	#$common->msg_debug("repos = ${repos}");
	(my $reposbase, my $reposdir, my $reposext) = fileparse ($repos);
	my $reposname = $reposbase . $reposext;

	my $repos_bak = "$repos/../../svn-bak/${reposname}-bak/prop/";
	$repos_bak = File::Spec->canonpath ($repos_bak);
	#$common->msg_debug("repos-bak = ${repos_bak}");

	(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst) = gmtime(time);
	my $now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec);
	#$common->msg_debug("$now");

	my $prefix = common::safe_name ("r${revision}|prop-${propname}|${now}|${action}|${user}|");
	my $suffix = ".dat";

	### get the property value
	my $old_value = `svnlook propget -r $revision --revprop $repos $propname`;

	#$common->msg_debug("old value: $old_value");
	#$common->msg_debug("new value: $new_value");

	if ( ! -e $repos_bak )
	{
		make_path ($repos_bak);
	}

	$common->write_value ( "${repos_bak}/${prefix}0.old${suffix}", $old_value, $return );
	$common->write_value ( "${repos_bak}/${prefix}1.new${suffix}", $new_value, $return );
}

### ===========================================================================
### Finish

$common->msg_exit_code($return);
$common->msg_now_banner(1);
exit $return;
