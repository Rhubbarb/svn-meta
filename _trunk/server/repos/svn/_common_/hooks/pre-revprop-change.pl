#!/usr/bin/perl

### Parameters

$repos = $ARGV[0];
$revision = $ARGV[1];
$user = $ARGV[2];
$propname = $ARGV[3];
$action = $ARGV[4]; ### 'A'dded, 'M'odified, or 'D'eleted
$new_value = <STDIN>;

### Options

$allow_property_changes = 1; ### prefer not to have script than set this to 0

$allow_only_log_modification = 1;
$backup_values = 1;

### Variables

### Result

$return = ($allow_property_changes ? 0 : 1);
#$return = 2; ### test value

### ===========================================================================
### Class

$common = common->spawn("pre-revprop-change", $repos);

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
	$is_standard = (substr($propname,0,4) eq "svn:");
	
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
	($reposbase, $reposdir, $reposext) = fileparse ($repos);
	$reposname = $reposbase . $reposext;

	$repos_bak = "$repos/../../svn-bak/${reposname}-bak/prop/";
	$repos_bak = File::Spec->canonpath ($repos_bak);
	#$common->msg_debug("repos-bak = ${repos_bak}");

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	$now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec);
	#$common->msg_debug("$now");

	$prefix = common::safe_name ("r${revision}|prop-${propname}|${now}|${action}|${user}|");
	$suffix = ".dat";
	
	### get the property value
	$old_value = `svnlook propget -r $revision --revprop $repos $propname`;

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
