#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository POST-REVPROP-CHANGE Hook
### -----------------------------------------------------
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
#my @old_value = <STDIN>;
#my $old_value = join ('', @old_value);

### Options

my $create_revision_dump = 1;

### Variables

### No result

my $return = 0; ### (only declared because strict)

### ===========================================================================
### Class

my $common = common->spawn("post-revprop-change", $repos);

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
### Perform a dump of the revision

### store in svn-bak/reposname-bak/dump/rev_prop-at.dat

if ($create_revision_dump)
{
	#$common->msg_debug("repos = ${repos}");
	(my $reposbase, my $reposdir, my $reposext) = fileparse ($repos);
	my $reposname = $reposbase . $reposext;

	my $repos_bak = "$repos/../../svn-bak/${reposname}-bak/dump/";
	$repos_bak = File::Spec->canonpath ($repos_bak);
	#$common->msg_debug("repos-bak = ${repos_bak}");

	my $now = common::today_now();
	#$common->msg_debug("$now");

	my $prefix = common::safe_file_name ("r${revision}|${now}");
	my $suffix = ".dat";

	### get the property value
	#my $new_value = `svnlook propget -r $revision --revprop $repos $propname`;

	#$common->msg_debug("old value: $old_value");
	#$common->msg_debug("new value: $new_value");

	if ( ! -e $repos_bak )
	{
		make_path ($repos_bak);
	}

	#$common->write_value ( "${repos_bak}/${prefix}0.old${suffix}", $old_value, $return );
	#$common->write_value ( "${repos_bak}/${prefix}1.new${suffix}", $new_value, $return );

	### write the dumpdata
	#`svnadmin dump $repos --incremental -r $revision > "${repos_bak}/${prefix}${suffix}"`;
	### why doesn't that work reliably??
	my $dump = `svnadmin dump $repos --incremental -r $revision`;
	$common->write_value ( "${repos_bak}/${prefix}${suffix}", $dump, $return );
}

### ===========================================================================
### Finish

#$common->msg_exit_code($return);
$common->msg_now_banner(1);
#exit $return;
