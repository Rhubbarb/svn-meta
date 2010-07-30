#!/usr/bin/perl

### Parameters

$repos = $ARGV[0];
$user = $ARGV[1];
$capabilities = $ARGV[2];

### Options

### Variables

### Result

$return = 0;

### ===========================================================================
### Class

$common = common->spawn("start-commit", $repos);

$common->msg_now_banner(0);
$common->msg_info_log_only("user=$user");

### ===========================================================================
### Modules to use

#use File::Basename;

### ---------------------------------------------------------------------------
### Function definitions

use subroutine::common;

### ===========================================================================
### Get the repository information

$youngest = `svnlook youngest $repos`;

### ---------------------------------------------------------------------------
### Split the capability information

@capabilities = split(/:/, $capabilities);

### ===========================================================================
### Start

#$common->msg_debug("capabilities = $capabilities");

### ---------------------------------------------------------------------------
### Check for required capabilities

if (1) ### mandatory for any SVN 1.5+ repository and server
{
	$mergeinfo_capable = 0; ### false

	foreach $capability (@capabilities)
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
