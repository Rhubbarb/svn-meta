#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository START-COMMIT Hook
### ----------------------------------------------
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
my $user = $ARGV[1];
my $capabilities = $ARGV[2];

### Result

my $return = 0;
#$return = 2; ### test value

### ===========================================================================
### Class

my $common = common->spawn("start-commit", $repos);
$common->msg_now_banner(0);
$common->msg_info_log_only("user=$user");
#$common->msg_debug("capabilities = $capabilities");

$common->load_options($return);

### Options

	my $disable_all_commits = $common->get_config_option
	  ('disable_all_commits', 0, $return);

### Variables

### ===========================================================================
### Modules to use

#use File::Basename;

### ---------------------------------------------------------------------------
### Function definitions

use subroutine::common;

### ===========================================================================
### Get the repository information

my $youngest = `svnlook youngest $repos`;

### ---------------------------------------------------------------------------
### Split the capability information

my @capabilities = split(/:/, $capabilities);

### ===========================================================================
### Start

if ($disable_all_commits)
{
	$common->msg_caught("all commits to this repository have been disabled by the administrator.", $return);
}

### ---------------------------------------------------------------------------
### Check for required capabilities

if (1) ### mandatory for any SVN 1.5+ repository and server
{
	my $mergeinfo_capable = 0; ### false

	foreach my $capability (@capabilities)
	{
		chomp($capability);
		$common->msg_debug("capability: $capability");
		if ($capability eq "mergeinfo")
		{
			$mergeinfo_capable = 1; ### true
		}
	}

	if (! $mergeinfo_capable)
	{
		$common->msg_caught("your SVN client is not mergeinfo-capable.", $return);
	}
}

### ===========================================================================
### Finish

$common->msg_exit_code($return);
$common->msg_now_banner(1);
exit $return;
