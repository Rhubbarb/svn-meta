#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository PRE-COMMIT Hook
### --------------------------------------------
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
my $txn = $ARGV[1];

### Options

my $check_message_nonempty = 1;
my $check_author_and_date_present = 1;
my $enable_path_checks = 1;
my $enable_property_checks = 1;
my $enable_line_checks = 1;
my $prevent_double_copying = 1;
my $enable_tag_protection = 1;
my $prevent_copy_from_tag = 1;
### per-user, per-directory access_control is achieved via ../conf/authz

### Variables

my $tagarea = "_tags";

### Result

my $return = 0;
#$return = 2; ### test value

### ===========================================================================
### Class

my $common = common->spawn("pre-commit", $repos);

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

(my $repos_url = $repos) =~ s(\\)(/)g;
$repos_url = "file:///" . $repos_url;

### ===========================================================================
### Get the whole-transaction information

#my $message = `svnlook propget -t $txn $repos --revprop svn:log`;
my $message = `svnlook log -t $txn $repos`;

#my $author = `svnlook propget -t $txn $repos --revprop svn:author`;
my $author = `svnlook author -t $txn $repos`;
chomp($author);

my $date = `svnlook propget -t $txn $repos --revprop svn:date`;
chomp($date);

#my @dirs_changed = `svnlook dirs-changed -t $txn $repos`;

my @changed = `svnlook changed -t $txn $repos`;

my @changes_with_copies = `svnlook changed --copy-info -t $txn $repos`;

### ---------------------------------------------------------------------------
### Get the repository information

my $youngest = `svnlook youngest $repos`;
my $potential_rev = $youngest + 1;

$common->msg_info_log_only("txn=$txn, author=$author, next-rev?=$potential_rev");
 
### ---------------------------------------------------------------------------
### Parse the filename, property and line configuration files

my $hookpath = File::Spec->canonpath ("$repos/../_common_/hooks/hook_config");

my @filename_config = ();
if ($enable_path_checks)
{
	my $success = open (my $fh, '<', "$hookpath/file-config.txt");
	if ($success)
	{
		my @config_lines = <$fh>;
		my $linenum = 0;
		foreach my $line (@config_lines)
		{
			++ $linenum;
			chomp ($line);
			if ($line eq "" or $line ~~ /^\s+$/ or $line ~~ /^\s*\#/)
			{
				### ignore the line
			}
			elsif ($line ~~ /^\s*([-+])\s*re\s*<(.*[^\s])>\s*$/) ### re<>
			{
				my $allowed = ($1 eq "+");
				my $pattern_str = $2;
				#$common->msg_debug(">>> re<$pattern_str>");
				push (@filename_config, [qr($pattern_str), $allowed]);
			}
			elsif ($line ~~ /^\s*([-+])\s*g\s*<\s*(.*[^\s])\s*>\s*$/) ### g<>
			{
				my $allowed = ($1 eq "+");
				my @globs = split(/\s+/,$2);
				for my $glob (@globs)
				{
					my $pattern_str = "/" . glob_to_regex_string($glob);
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

my %property_config = ();
if ($enable_property_checks)
{
	my $success = open (my $fh, '<', "$hookpath/prop-config.txt");
	if ($success)
	{
		my @config_lines = <$fh>;
		my $linenum = 0;
		my @globs = ();
		foreach my $line (@config_lines)
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
				my $required = ($1 eq "+");
				my $prohibited = ($1 eq "-");
				my $prop_name = $2;
				my $prop_value = $3;
				foreach my $glob (@globs)
				{
					$property_config{$glob}{$prop_name} = [$required, $prohibited, $prop_value];
				}
			}
			elsif ($line ~~ /^\s*([-+=])\s*(.*[^\s])\s*$/)
			{
				my $required = ($1 eq "+");
				my $prohibited = ($1 eq "-");
				my $prop_name = $2;
				foreach my $glob (@globs)
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

my %line_config = ();
if ($enable_line_checks)
{
	my $success = open (my $fh, '<', "$hookpath/line-config.txt");
	if ($success)
	{
		my @config_lines = <$fh>;
		my $linenum = 0;
		my @globs = ();
		foreach my $line (@config_lines)
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
				my $prohibited = ($1 eq "-");
				my $desc = $2;
				my $pattern_str = $3;
				foreach my $glob (@globs)
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
	foreach my $changed (@changed)
	{
		chomp($changed);
		my $file_action = substr($changed,0,1);
		my $meta_action = substr($changed,1,1);
		my $with_history = substr($changed,2,1);
		my $filepath = substr($changed,4);

		(my $filebase, my $filedir, my $fileext) = fileparse ($filepath);
		my $filename = $filebase . $fileext;
		my $is_directory = ($filename eq "");

		#$common->msg_debug("$file_action$meta_action$with_history $filedir$filebase$fileext");

		if (($file_action eq "A")
			&& ! $is_directory
			&& ($with_history eq " ")
			)
		{
			### check that the new file may be added (extension or pattern)
			if ($enable_path_checks)
			{
				my $allowed = 1;
				foreach my $entry (@filename_config)
				{
					my $pattern = $entry->[0];
					my $allowed = $entry->[1];
					
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
				while((my $glob, my $props) = each(%property_config))
				{
					if ($filename ~~ glob_to_regex($glob))
					{
						while((my $prop_name, my $entry) = each(%{$props}))
						{
							my $prop_value_actual = `svnlook propget -t $txn $repos $prop_name $filepath 2> nul`;
							my $exists = not $?;
							special_filter ($prop_name, \$prop_value_actual);
	
							my $prop_value_specified = $entry->[2];
							special_filter ($prop_name, \$prop_value_specified);
							my $required = $entry->[0];
							my $prohibited = $entry->[1];
							
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
				my $catch = 1;
				
				### the only permissible exceptions to a tag edit are
				### deletion of an entire tag
				### new atomic additions and modifications (i.e. a new tag)
				if ($file_action eq "D")
				{
					my @log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$filepath`;
					for my $log (@log)
					{
						chomp($log);
						if ($log ~~ /   [A] (.+) \(from (.+):([0-9]+)\)/)
						{
							(my $log_to_path = $1) =~ s(^/)();
							#my $log_from_path = $2;
							#my $log_from_rev = $3;

							(my $txn_path = $filepath) =~ s(/$)();
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
					(my $txn_parent = $filepath) =~ s(/[^/]+/?$)();
					#$common->msg_debug("parent = $repos_url/$txn_parent");
					my @log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$txn_parent 2> nul`;
					my $log_error = $?;
					#$common->msg_debug("err = $log_error");
					if ($log_error)
					{
						### okay: this is the creation of a new (possibly complex) tag
						$catch = 0;
					}
					for my $log (@log)
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

	my $txn_mode = ();
	my $txn_from_path = ();
	my $txn_to_path = ();
	my $txn_from_rev = ();

	for my $changed_copy (@changes_with_copies)
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
				(my $txn_to_parent = $txn_to_path) =~ s(/[^/]+/?$)();
				#$common->msg_debug("parent = $repos_url/$txn_to_parent");
				my @log = `svn log --stop-on-copy -qvr1:HEAD --limit 1 $repos_url/$txn_to_parent`;
				#$common->msg_debug("@log");

				for my $log (@log)
				{
					chomp($log);
					if ($log ~~ /   [A] (.+) \(from (.+):([0-9]+)\)/)
					{
						#my $log_to_path = $1;
						(my $log_from_path = $2) =~ s(^/)();
						#my $log_from_rev = $3;

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
	my @diffs = `svnlook diff -t $txn $repos --no-diff-deleted --diff-copy-from`;
	my $fileaction = ();
	my $filepath = ();
	my $line_num = 0;
	#print STDERR @diffs;
	my %patterns = ();
	foreach my $diff (@diffs)
	{
		chomp($diff);
		my $line_inc = 1;
		if ($diff ~~ /^(Added|Modified|Deleted): (.*)$/)
		{
			$fileaction = $1;
			$filepath = $2;

			(my $filebase, my $filedir, my $fileext) = fileparse ($filepath);
			my $filename = $filebase . $fileext;
			#my $is_directory = ($filename eq "");

			### pre-select the sub-collection of patterns to apply
			%patterns = ();
			while((my $glob, my $pattern_strs) = each(%line_config))
			{
				if ($filename ~~ glob_to_regex($glob))
				{
					while((my $pattern_str, my $entry) = each(%{$pattern_strs}))
					{
						$patterns{$pattern_str} = $entry;
					}
				}
			}
		}
		elsif ($diff ~~ /^Property changes on: .*$/)
		{
			$filepath = ();
			%patterns = ();
		}
		elsif ($diff ~~ /^@@ -([0-9]+)(?:,([0-9]+))? \+([0-9]+)(?:,([0-9]+))? @@$/)
		{
			#my $old_pos = common::default_int ($1,0);
			#my $old_len = common::default_int ($2,1);
			my $new_pos = common::default_int ($3,0);
			#my $new_len = common::default_int ($4,1);

			#$common->msg_debug("$diff");
			#$common->msg_debug("@ $old_pos,$old_len $new_pos,$new_len");

			$line_num = $new_pos - 1;
		}
		elsif ($diff ~~ /^([-+])([^+].*)$/)
		{
			my $lineaction = $1;
			my $line = $2;
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
					while((my $pattern_str, my $entry) = each(%patterns))
					{
						my $desc = @{$entry}[0];
						my $pattern = @{$entry}[1];
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
