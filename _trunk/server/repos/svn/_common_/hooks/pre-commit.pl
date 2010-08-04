#!/usr/bin/perl

###############################################################################
###
### Copyright � 2010 Rob Hubbard.
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

### Parameters

$repos = $ARGV[0];
$txn = $ARGV[1];

### Options

$check_message_nonempty = 1;
$check_author_and_date_present = 1;
$enable_path_checks = 1;
$enable_property_checks = 1;
$enable_line_checks = 1;
$prevent_double_copying = 1;
$enable_tag_protection = 1;
$prevent_copy_from_tag = 1;
### per-user, per-directory access_control is achieved via ../conf/authz

### Variables

$tagarea = "_tags";

### Result

$return = 0;
#$return = 2; ### test value

### ===========================================================================
### Class

$common = common->spawn("pre-commit", $repos);

$common->msg_now_banner(0);

### ===========================================================================
### Modules to use

use File::Basename;
use File::Spec;
use Text::Glob qw( match_glob glob_to_regex glob_to_regex_string );

#use XML::LibXML; ### installation problem
#use XML::Simple;

### ---------------------------------------------------------------------------
### Function definitions

use subroutine::common;

sub special_filter ($$)
{
	my $prop_name = shift;
	my $prop_value = shift;
	
	if ($prop_name eq "svn:keywords")
	{
		my @keywords = split(/ +/,$$prop_value);
		my @new_keywords = ();
		foreach my $keyword (@keywords)
		{
			$keyword = "Date" if $keyword eq "LastChangedDate";
			$keyword = "Rev" if ($keyword eq "Revision" or $keyword eq "LastChangedRevision");
			$keyword = "Author" if $keyword eq "LastChangedBy";
			$keyword = "URL" if $keyword eq "HeadURL";
			#"Id"
			
			@new_keywords = (@new_keywords, $keyword);
		}
		@new_keywords = sort(@new_keywords);
		$$prop_value = join(" ",@new_keywords);
	}
}

### ===========================================================================
### Defines

($repos_url = $repos) =~ s(\\)(/)g;
$repos_url = "file:///" . $repos_url;

### ===========================================================================
### Get the whole-transaction information

#$message = `svnlook propget -t $txn $repos --revprop svn:log`;
$message = `svnlook log -t $txn $repos`;

#$author = `svnlook propget -t $txn $repos --revprop svn:author`;
$author = `svnlook author -t $txn $repos`;
chomp($author);

$date = `svnlook propget -t $txn $repos --revprop svn:date`;
chomp($date);

#@dirs_changed = `svnlook dirs-changed -t $txn $repos`;

@changed = `svnlook changed -t $txn $repos`;

@changes_with_copies = `svnlook changed --copy-info -t $txn $repos`;

### ---------------------------------------------------------------------------
### Get the repository information

$youngest = `svnlook youngest $repos`;
$potential_rev = $youngest + 1;

$common->msg_info_log_only("txn=$txn, author=$author, next-rev?=$potential_rev");
 
### ---------------------------------------------------------------------------
### Parse the filename, property and line configuration files

$hookpath = File::Spec->canonpath ("$repos/../_common_/hooks/hook_config");

@filename_config = ();
if ($enable_path_checks)
{
	$success = open ($fh, '<', "$hookpath/file-config.txt");
	if ($success)
	{
		@config_lines = <$fh>;
		$linenum = 0;
		foreach $line (@config_lines)
		{
			++ $linenum;
			chomp ($line);
			if ($line eq "" or $line ~~ /^\s+$/ or $line ~~ /^\s*\#/)
			{
				### ignore the line
			}
			elsif ($line ~~ /^\s*([-+])\s*re\s*<(.*[^\s])>\s*$/) ### re<>
			{
				$allowed = ($1 eq "+");
				$pattern_str = $2;
				#$common->msg_debug(">>> re<$pattern_str>");
				push (@filename_config, [qr($pattern_str), $allowed]);
			}
			elsif ($line ~~ /^\s*([-+])\s*g\s*<\s*(.*[^\s])\s*>\s*$/) ### g<>
			{
				$allowed = ($1 eq "+");
				@globs = split(/\s+/,$2);
				for $glob (@globs)
				{
					$pattern_str = "/" . glob_to_regex_string($glob);
					#$common->msg_debug(">>> g<$glob> = re<$pattern_str>");
					push (@filename_config, [qr($pattern_str), $allowed]);
				}
			}
			else
			{
				$common->msg_error ("bad line $linenum in filename configuration file.", $return);
			}
		}
		close ($fh);
	}
	else
	{
		$common->msg_error ("could not find or read filename configuration file.", $return);
	}
}

%property_config = ();
if ($enable_property_checks)
{
	$success = open ($fh, '<', "$hookpath/prop-config.txt");
	if ($success)
	{
		@config_lines = <$fh>;
		$linenum = 0;
		@globs = ();
		foreach $line (@config_lines)
		{
			++ $linenum;
			chomp ($line);
			if ($line eq "" or $line ~~ /^\s+$/ or $line ~~ /^\s*\#/)
			{
				### ignore the line
			}
			elsif ($line ~~ /^\s*g\s*<\s*(.*)\s*>\s*$/)
			{
				@globs = split (/\s+/, $1);
			}
			elsif ($line ~~ /^\s*([-+=])\s*([^=]*[^=\s])\s*=\s*(.*[^\s])\s*$/)
			{
				$required = ($1 eq "+");
				$prohibited = ($1 eq "-");
				$prop_name = $2;
				$prop_value = $3;
				foreach $glob (@globs)
				{
					$property_config{$glob}{$prop_name} = [$required, $prohibited, $prop_value];
				}
			}
			elsif ($line ~~ /^\s*([-+=])\s*(.*[^\s])\s*$/)
			{
				$required = ($1 eq "+");
				$prohibited = ($1 eq "-");
				$prop_name = $2;
				foreach $glob (@globs)
				{
					$property_config{$glob}{$prop_name} = [$required, $prohibited, ()];
				}
			}
			else
			{
				$common->msg_error("bad line $linenum in property configuration file.", $return);
			}
		}
		close ($fh);
	}
	else
	{
		$common->msg_error("could not find or read property configuration file.", $return);
	}
}

%line_config = ();
if ($enable_line_checks)
{
	$success = open ($fh, '<', "$hookpath/line-config.txt");
	if ($success)
	{
		@config_lines = <$fh>;
		$linenum = 0;
		@globs = ();
		foreach $line (@config_lines)
		{
			++ $linenum;
			chomp ($line);
			if ($line eq "" or $line ~~ /^\s+$/ or $line ~~ /^\s*\#/)
			{
				### ignore the line
			}
			elsif ($line ~~ /^\s*g\s*<\s*(.*)\s*>\s*$/)
			{
				@globs = split (/\s+/, $1);
			}
			elsif ($line ~~ /^\s*([-])\s*<"(.*)">\s*re\s*<\s*(.*[^\s])>\s*$/)
			{
				#$required = ($1 eq "+");
				$prohibited = ($1 eq "-");
				$desc = $2;
				$pattern_str = $3;
				foreach $glob (@globs)
				{
					$line_config{$glob}{$pattern_str} = [$desc,qr($pattern_str)];
				}
			}
			else
			{
				$common->msg_error("bad line $linenum in the line configuration file.", $return);
			}
		}
		close ($fh);
	}
	else
	{
		$common->msg_error("could not find or read the line configuration file.", $return);
	}
}

### ===========================================================================
### Start

#$common->msg_debug("repos = $repos");
#$common->msg_debug("txn = $txn");

#$common->msg_debug("author = $author");
#$common->msg_debug("message = $message");
#$common->msg_debug("$changed");
#print STDERR "@changed";

### ---------------------------------------------------------------------------
### Check the message
if ($check_message_nonempty)
{
	if (common::trim($message) eq "")
	{
		$common->msg_caught("empty message.", $return);
	}
}

### other message checks...?

### ---------------------------------------------------------------------------
### Check the other revision properties
if ($check_author_and_date_present)
{
	if ($author eq "")
	{
		$common->msg_caught("missing author.", $return);
	}
	else
	{
		#$common->msg_debug("author = [$author]");
	}

	if ($date eq "")
	{
		$common->msg_caught("missing date.", $return);
	}
	else
	{
		#$common->msg_debug("date = [$date]");
	}
}

### ---------------------------------------------------------------------------
### Perform checks for each modified path
if ($enable_path_checks or $enable_property_checks
		or $enable_tag_protection)
{
	foreach $changed (@changed)
	{
		chomp($changed);
		$file_action = substr($changed,0,1);
		$meta_action = substr($changed,1,1);
		$with_history = substr($changed,2,1);
		$filepath = substr($changed,4);

		($filebase, $filedir, $fileext) = fileparse ($filepath);
		$filename = $filebase . $fileext;
		$is_directory = ($filename eq "");

		#$common->msg_debug("$file_action$meta_action$with_history $filedir$filebase$fileext");

		if (($file_action eq "A")
			&& ! $is_directory
			&& ($with_history eq " ")
			)
		{
			### check that the new file may be added (extension or pattern)
			if ($enable_path_checks)
			{
				$allowed = 1;
				foreach $entry (@filename_config)
				{
					$pattern = $entry->[0];
					$allowed = $entry->[1];
					
					if ("/".$filepath ~~ $pattern)
					{
						last;
					}
				}
				unless ($allowed)
				{
					$common->msg_caught("<$filepath> blocked.", $return);
				}
			}

			if ($enable_property_checks)
			{
				while(($glob, $props) = each(%property_config))
				{
					if ($filename ~~ glob_to_regex($glob))
					{
						while(($prop_name, $entry) = each(%{$props}))
						{
							$prop_value_actual = `svnlook propget -t $txn $repos $prop_name $filepath 2> nul`;
							$exists = not $?;
							special_filter ($prop_name, \$prop_value_actual);
	
							$prop_value_specified = $entry->[2];
							special_filter ($prop_name, \$prop_value_specified);
							$required = $entry->[0];
							$prohibited = $entry->[1];
							
							if ($exists)
							{
								if ($prohibited)
								{
									$common->msg_caught("<$filepath> prop $prop_name prohibited for <$glob>.", $return);
								}
								elsif ($prop_value_specified)
								{
									unless ($prop_value_actual eq $prop_value_specified)
									{
										$common->msg_caught("<$filepath> prop $prop_name value not \"$prop_value_specified\" for <$glob>.", $return);
									}
								}
							}
							else
							{
								if ($required)
								{
									$common->msg_caught("<$filepath> prop $prop_name=$prop_value_specified required for <$glob>.", $return);
								}
							}
						}
						last; ### consider only the first filename glob match
					}
				}
			}
		}
		
		if ($enable_tag_protection)
		{
			if ("/".$filepath."/" ~~ /\/$tagarea\//)
			{
				$catch = 1;
				
				### the only permissible exceptions to a tag edit are
				### deletion of an entire tag
				### new atomic additions and modifications (i.e. a new tag)
				if ($file_action eq "D")
				{
					@log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$filepath`;
					for $log (@log)
					{
						chomp($log);
						if ($log ~~ /   [A] (.+) \(from (.+):([0-9]+)\)/)
						{
							($log_to_path = $1) =~ s(^/)();
							#$log_from_path = $2;
							#$log_from_rev = $3;

							($txn_path = $filepath) =~ s(/$)();
							#$common->msg_debug("$txn_path =? $log_to_path");
							if ($txn_path eq $log_to_path)
							{
								### okay: this is deletion of a whole tag
								$catch = 0;
							}
						}
					}
				}

				if ($catch)
				{
					($txn_parent = $filepath) =~ s(/[^/]+/?$)();
					#$common->msg_debug("parent = $repos_url/$txn_parent");
					@log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$txn_parent 2> nul`;
					$log_error = $?;
					#$common->msg_debug("err = $log_error");
					if ($log_error)
					{
						### okay: this is the creation of a new (possibly complex) tag
						$catch = 0;
					}
					for $log (@log)
					{
						chomp($log);
						if ($log ~~ /^   [AMD] /)
						{
							unless ($log ~~ /^   [A] (.+) \(from (.+):([0-9]+)\)/)
							{
								### okay: this is the creation of a new tag
								$catch = 0;
								### Q: make this universal rather than existential?
							}
						}
					}
				}

				if ($catch)
				{
					$common->msg_caught("<$filepath> modification of tag.", $return);
				}
			}
		}
	}
}

if ($prevent_double_copying
	or $prevent_copy_from_tag)
{
	#$common->msg_debug("\n@changes_with_copies");

	for $changed_copy (@changes_with_copies)
	{
		chomp($changed_copy);
		
		if ($changed_copy ~~ /^([AUD]) ([+ ]) (.*)$/)
		{
			$txn_mode = $1 . $2;
			$txn_to_path = $3;
		}
		elsif ($changed_copy ~~ /^\s*\(from (.*):r([0-9]+)\)$/)
		{
			($txn_from_path = $1) =~ s(/$)();
			$txn_from_rev = $2;

			if ($prevent_copy_from_tag
				and $txn_mode ~~ /^.+$/)
			{
				if ("/".$txn_from_path."/" ~~ /\/$tagarea\//)
				{
					$common->msg_caught("<$txn_to_path ($txn_from_path)> rename or copy from tag.", $return);
					$common->msg_advice("copy from the source of the tag, not the tag itself.");
				}
			}

			if ($prevent_double_copying
				and $txn_mode eq "A+")
			{
				### find the revision in which the parent was created
				### (did this have history?)
				($txn_to_parent = $txn_to_path) =~ s(/[^/]+/?$)();
				#$common->msg_debug("parent = $repos_url/$txn_to_parent");
				@log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$txn_to_parent`;
				#$common->msg_debug("@log");

				for $log (@log)
				{
					chomp($log);
					if ($log ~~ /   [A] (.+) \(from (.+):([0-9]+)\)/)
					{
						#$log_to_path = $1;
						($log_from_path = $2) =~ s(^/)();
						#$log_from_rev = $3;

						#$common->msg_debug("$log_from_path =? $txn_from_path");
						if ($prevent_double_copying
							and $log_from_path eq $txn_from_path)
						{
							$common->msg_caught("<$txn_to_path> path copy into already-copied path.", $return);
						}
					}
				}
			}
		}
	}
}

### ---------------------------------------------------------------------------
### Perform checks on file differences
if ($enable_line_checks)
{
	@diffs = `svnlook diff -t $txn $repos --no-diff-deleted --diff-copy-from`;
	$action = ();
	$filepath = ();
	$line_num = 0;
	#print STDERR @diffs;
	%patterns = ();
	foreach $diff (@diffs)
	{
		chomp($diff);
		$line_inc = 1;
		if ($diff ~~ /^(Added|Modified|Deleted): (.*)$/)
		{
			$fileaction = $1;
			$filepath = $2;

			($filebase, $filedir, $fileext) = fileparse ($filepath);
			$filename = $filebase . $fileext;
			#$is_directory = ($filename eq "");

			### pre-select the sub-collection of patterns to apply
			%patterns = ();
			while(($glob, $pattern_strs) = each(%line_config))
			{
				if ($filename ~~ glob_to_regex($glob))
				{
					while(($pattern_str, $entry) = each(%{$pattern_strs}))
					{
						$patterns{$pattern_str} = $entry;
					}
				}
			}
		}
		elsif ($diff ~~ /^Property changes on: .*$/)
		{
			$filepath = ();
			@patterns = ();
		}
		elsif ($diff ~~ /^@@ -([0-9]+)(?:,([0-9]+))? \+([0-9]+)(?:,([0-9]+))? @@$/)
		{
			#$old_pos = common::default_int ($1,0);
			#$old_len = common::default_int ($2,1);
			$new_pos = common::default_int ($3,0);
			#$new_len = common::default_int ($4,1);

			#$common->msg_debug("$diff");
			#$common->msg_debug("@ $old_pos,$old_len $new_pos,$new_len");

			$line_num = $new_pos - 1;
		}
		elsif ($diff ~~ /^([-+])([^+].*)$/)
		{
			$lineaction = $1;
			$line = $2;
			chomp ($line);
			if ($lineaction eq "-")
			{
				### don't count deleted lines
				$line_inc = 0;
			}
			elsif ($filepath)
			{
				if ($fileaction ~~ /^(Added|Modified)$/)
				{
					### check this line against our rules
					while(($pattern_str, $entry) = each(%patterns))
					{
						$desc = @{$entry}[0];
						$pattern = @{$entry}[1];
						if ($line ~~ $pattern)
						{
							$common->msg_caught("<$filepath($line_num)> matches prohibited \"$desc\".", $return); ### " /$pattern_str/"
						}
					}
				}
			}
			else
			{
				$common->msg_error("error processing line differences.", $return);
			}
		}
		$line_num += $line_inc;
	}
}

### ===========================================================================
### Finish

$common->msg_exit_code($return);
$common->msg_now_banner(1);
exit $return;
