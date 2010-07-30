#!/usr/bin/perl

### Parameters

$repos = $ARGV[0];
$revision = $ARGV[1];
$user = $ARGV[2];
$propname = $ARGV[3];
$action = $ARGV[4]; ### 'A'dded, 'M'odified, or 'D'eleted
#$old_value = <STDIN>;

### Options

$create_revision_dump = 1;

### Variables

### No result

#$return = 0;

### ===========================================================================
### Class

$common = common->spawn("post-revprop-change", $repos);

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
	($reposbase, $reposdir, $reposext) = fileparse ($repos);
	$reposname = $reposbase . $reposext;

	$repos_bak = "$repos/../../svn-bak/${reposname}-bak/dump/";
	$repos_bak = File::Spec->canonpath ($repos_bak);
	#$common->msg_debug("repos-bak = ${repos_bak}");

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	$now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec);
	#$common->msg_debug("$now");

	$prefix = common::safe_name ("r${revision}|${now}");
	$suffix = ".dat";
	
	### get the property value
	#$new_value = `svnlook propget -r $revision --revprop $repos $propname`;

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
	$dump = `svnadmin dump $repos --incremental -r $revision`;
	$common->write_value ( "${repos_bak}/${prefix}${suffix}", $dump, $return );
}

### ===========================================================================
### Finish

#$common->msg_exit_code($return);
$common->msg_now_banner(1);
#exit $return;
