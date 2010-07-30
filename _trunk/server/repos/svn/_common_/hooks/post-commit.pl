#!/usr/bin/perl

### Parameters

$repos = $ARGV[0];
$revision = $ARGV[1];

### Options

$create_revision_dump = 1;
#$send_mail = 0; ### NOT IMPLEMENTED

### Variables

### No result

#$return = 0;

### ===========================================================================
### Class

$common = common->spawn("post-commit", $repos);

$common->msg_now_banner(0);
$common->msg_info_log_only("rev=$revision");

### ===========================================================================
### Modules to use

use File::Basename;
use File::Path 'make_path';
use File::Spec;
#use Date::Calc;
use Mail::Sendmail;

### ---------------------------------------------------------------------------
### Function definitions

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

### store in svn-bak/reposname-bak/prop/rev_prop.dat

if ($create_revision_dump)
{
	#$common->msg_debug("repos = ${repos}");
	($reposbase, $reposdir, $reposext) = fileparse ($repos);
	$reposname = $reposbase . $reposext;

	$repos_bak = "$repos/../../svn-bak/${reposname}-bak/dump/";
	$repos_bak = File::Spec->canonpath ($repos_bak);
	#$common->msg_debug("repos-bak = ${repos_bak}");

	#($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	#$now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec);
	#$common->msg_debug("$now");

	$prefix = common::safe_name ("r${revision}");
	$suffix = ".dat";
	
	if ( ! -e $repos_bak )
	{
		make_path ($repos_bak);
	}

	### write the dumpdata
	`svnadmin dump $repos --incremental -r $revision > "${repos_bak}/${prefix}${suffix}"`;
}

### ---------------------------------------------------------------------------
### Mail

if ($send_mail)
{
	# ...
}

### ===========================================================================
### Finish

#$common->msg_exit_code($return);
$common->msg_now_banner(1);
#exit $return;
