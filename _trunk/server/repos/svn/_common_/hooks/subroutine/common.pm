#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository Hook Common Subroutine Module
### ----------------------------------------------------------
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

package common;

### Options

my $logging_enabled = 1;
my $debugging_enabled = 0;
my $show_options = 0;

### Variables

### ===========================================================================
### Modules to use

use Time::HiRes qw(gettimeofday);
use File::Spec;
#use Cwd;

### ===========================================================================
# Declarations of Functions

# Perl trim function to remove whitespace from the start and end of the string
sub trim ($); ### ($string)

sub default_int ($$); ### ($str, $default)

sub safe_file_name ($); ### ($fn)

sub today_now_iso8601_utc ();
sub today_iso8601_utc ();
sub now_iso8601_utc ();

sub today_now ();
sub today ();
sub now ();

### ===========================================================================
# Declarations of Methods

### NB: prototypes not actually enforced for method calls

sub load_options ($\$); ### ($self, \$return)
sub get_config_option ($$$\$); ### ($self, $option_name, $default, \$return)
sub find_config_file ($$\$); ### ($self, $file_name, \$return)

sub msg_print ($$); ### ($self, $text)
sub msg_info_log_only ($$); ### ($self, $text)
sub msg_error ($$\$); ### ($self, $text, \$return)
sub msg_info ($$); ### ($self, $text)
sub msg_caught ($$\$); ### ($self, $text, \$return)
sub msg_advice ($$); ### ($self, $text)
sub msg_debug ($$); ### ($self, $text)
sub msg_now_banner($$$); ### ($self, $end)
sub msg_exit_code ($$); ### ($self, $return)
sub write_value ($$$\$); ### ($self, $fn, $text, \$return)

### ===========================================================================
# Definitions of Functions

sub trim ($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub default_int ($$)
{
	my $str = shift;
	my $default = shift;
	my $value = $default;
	if ($str ne "")
	{
		$value = int($str);
	}
	return $value;
}

sub safe_file_name ($) ### ($fn)
{
	my $fn = shift; ### $_[0]

	### Adjust a filename to be safe
	### and try to make the name convenient for shell use too,
	### so remove or change various special characters
	
	### characters:
	### <|> shell redirection
	### :\/ drive and directory separators (dos, unix)
	### ;: path separators (dos, unix)
	### %$ shell variables (dos, unix)
	### ?* file globs
	### `"' ()[]{} shell quoting and sub-shells
	### ^\ shell escape (dos, unix)

	### see also:
	### <http://en.wikipedia.org/wiki/Filename#Reserved_characters_and_words>

	### replace with visually similar character if possible
	$fn =~ s/[[({<]/_/g; ### open brackets
	$fn =~ s/[]({>]/_/g; ### close brackets
	$fn =~ s/[?*\$%]/#/g;
	$fn =~ s([/|\\])(!)g;
	$fn =~ s/[:;]/./g;
	$fn =~ s/["']/,/g;
	$fn =~ s/ /_/g; ### space
	
	### and delete anything else
	$fn =~ s/[^-_.,!+=@#a-zA-Z0-9]//g;

	return $fn;
}

sub today_now_iso8601_utc ()
{
	my $year, my $mon, my $mday;
	my $sec, my $min, my $hour;
	my $wday, my $yday, my $isdst; ### unused
	### UTC
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	### ISO 8601
	my $today_now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ",
		$year+1900,$mon+1,$mday, $hour,$min,$sec);
	return $today_now;
}

sub today_iso8601_utc ()
{
	my $year, my $mon, my $mday;
	my $sec, my $min, my $hour; ### unused
	my $wday, my $yday, my $isdst; ### unused
	### UTC
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	### ISO 8601
	my $today = sprintf ("%4d-%02d-%02d", $year+1900,$mon+1,$mday);
	return $today;
}

sub now_iso8601_utc ()
{
	my $year, my $mon, my $mday; ### unused
	my $sec, my $min, my $hour;
	my $wday, my $yday, my $isdst; ### unused
	### UTC
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	### ISO 8601
	my $now = sprintf ("%02d:%02d:%02dZ", $hour,$min,$sec);
	return $now;
}

sub today_now ()
{
	return today_now_iso8601_utc ();
}

sub today ()
{
	return today_iso8601_utc ();
}

sub now ()
{
	return now_iso8601_utc ();
}

### ===========================================================================
# Definitions of Methods

sub spawn ($$$) ### ($class, $hook, $repos)
{
	my $class = shift;
	my $hook = shift;
	my $repos = shift;
	#my $return = \shift;

	(my $repos_base = $repos) =~ s(^.*[\/\\])();

	my $self =
	{
		'hook' => $hook,
		'repos' => $repos,
		'repos_base' => $repos_base,
		'time_s' => 0,
		'time_us' => 0,
	};

	bless ($self, $class);
	return $self;
}

sub load_options ($\$) ### ($self, \$return)
{
	my $self = shift;
	my $return = \shift;

	my $repos = $self->{repos_base};

	my %global_options = ();
	my %repos_options = ();

	#my $cwd = cwd();
	#$self->msg_print("cwd = $cwd");

	### load global options
	$self->_parse_options (\%global_options, "_common_", "./hook_config/options.txt", $return);

	### load repository-specific options (these will take precedence)
	$self->_parse_options (\%repos_options, $repos, "./../../$repos/hooks/_hook_config/options.txt", $return);

	### merge these hashes
	my %options = %global_options;
	while ( (my $key, my $value) = each %repos_options )
	{
		$options{$key} = $value;
	}

	while ( (my $key, my $value) = each %options )
	{
		if ($show_options)
		{
			if (exists $global_options{$key})
			{
				if (exists $repos_options{$key})
				{
					$self->msg_print ("READ OPTION: {$key} = REPOS {$value} [overridden GLOBAL {$global_options{$key}}]");
				}
				else
				{
					$self->msg_print ("READ OPTION: {$key} = GLOBAL {$value}");
				}
			}
			else
			{
				$self->msg_print ("READ OPTION: {$key} = REPOS {$value}");
			}
		}
		$self->{'options'}->{$key} = $value;
	}
}

## pseudo-private
sub _parse_options ($$$$\$) ### ($self, \%options, $repos, $file_name, \$return)
{
	my $self = shift;
	my $options = shift;
	my $label = shift;
	my $file_name = shift;
	my $return = \shift;

	my $hook = $self->{hook};
	my $repos = $self->{repos_base};

	if ( -e $file_name )
	{
		my $success = open (my $fh, "<", $file_name);

		if ($success)
		{
			my @config_lines = <$fh>;
			my $linenum = 0;
			my $active = 0;
			foreach my $line (@config_lines)
			{
				++ $linenum;
				chomp ($line);
				if ($line eq "" or $line ~~ /^\s+$/ or $line ~~ /^\s*\#/)
				{
					### ignore the line
				}
				elsif ($line ~~ /^\s*\[(.*)\]\s*$/) ### [section]
				{
					my $section = $1;
					$active = ($section eq $hook);
				}
				elsif ($line ~~ /^\s*\$?([^=\s]*)\s*=\s*(.*[^;\s])[;\s]*(?:#.*)?$/)
				{
					if ($active)
					{
						my $option_name = $1;
						my $value = eval ($2);

						$options->{$option_name} = $value;
					}
				}
				else
				{
					$self->msg_error("bad line $linenum in $label options file.", $return);
				}
			}
			close ($fh);
		}
		else
		{
			$self->msg_error("failure to read $label options file $file_name.", $return);
		}
	}
	else
	{
		$self->msg_info("no $label options file $file_name.");
	}
}

sub get_config_option ($$$\$) ### ($self, $option_name, $default, \$return)
{
	my $self = shift;
	my $option_name = shift;
	my $default = shift;
	my $return = \shift;

	my $value;
	if ( defined $self->{'options'}->{$option_name} )
	{
		$value = $self->{'options'}->{$option_name};
	}
	else
	{
		$value = $default;
		if ($show_options)
		{
			$self->msg_print ("OPTION: {$option_name} = DEFAULT {$value}");
		}
	}

	return $value;
}

sub find_config_file ($$\$) ### ($self, $file_name, \$return)
{
	my $self = shift;
	my $file_name = shift;
	my $return = \shift;

	my $repos = $self->{'repos'};
	my $repos_path = File::Spec->canonpath ("$repos/hooks/_hook_config/$file_name");
	my $common_path = File::Spec->canonpath ("$repos/../_common_/hooks/hook_config/$file_name");

	#print STDERR ("$repos_path\n$common_path\n");

	my $path = ();
	if ( -e $repos_path )
	{
		if ($show_options)
		{
			$self->msg_print ("CONFIG: REPOS {$file_name}");
		}
		$path = $repos_path;
	}
	elsif ( -e $common_path )
	{
		if ($show_options)
		{
			$self->msg_print ("CONFIG: GLOBAL {$file_name}");
		}
		$path = $common_path;
	}
	else
	{
		$self->msg_error ("no configuration file <$file_name> found.", $$return);
	}

	return $path;
}

sub msg_print ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;

	print STDERR "$text\n";
	$self->_msg_to_log($text) if ($logging_enabled);
}

sub msg_info_log_only ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;

	$self->_msg_to_log("INFO: $text") if ($logging_enabled);
}

sub msg_error ($$\$) ### ($self, $text, \$return)
{
	my $self = shift;
	my $text = shift;
	my $return = \shift;
	
	$self->msg_print ("ERROR: $text");
	$$return = 1;
}

sub msg_info ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;

	$self->msg_print ("INFO: $text");
}

sub msg_caught ($$\$) ### ($self, $text, \$return)
{
	my $self = shift;
	my $text = shift;
	my $return = \shift;
	
	$self->msg_print ("CAUGHT: $text");
	$$return = 1;
}

sub msg_advice ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;
	
	$self->msg_print ("ADVICE: $text");
}

sub msg_debug ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;

	$self->msg_print ("[DEBUG: $text]") if ($debugging_enabled);
}

sub msg_now_banner($$$) ### ($self, $finish, $return)
{
	my $self = shift;
	my $finish = shift;

	(my $epochseconds, my $microseconds) = gettimeofday;

	my $duration_str = ();
	unless ($finish)
	{
		$self->{'time_s'} = $epochseconds;
		$self->{'time_us'} = $microseconds;
	}
	else ### if $finish
	{
		my $duration_us =
			1_000_000 * ($epochseconds - $self->{'time_s'})
			+ ($microseconds - $self->{'time_us'});

		my $duration_ms = int ($duration_us / 1000);

		$duration_str = sprintf ("%d.%03ds",
				$duration_ms / 1000,
				$duration_ms % 1000);
	}

	my $now = now();

	(my $repos_base = $common::repos) =~ s(^.*[\/\\])();
	my $label = ($finish ? "--- " : "$self->{repos_base} $self->{hook} ") . "$now"
			. ($finish ? " ($duration_str) ---" : "");
	my $len = length($label);
	my $to_pad = 79 - 2 - $len;
	my $left = int ($to_pad / 2);
	my $right = $to_pad - $left;
	#print STDERR "$len, $to_pad, $left, $right\n";
	my $lch = ($finish ? ' ' : '-');
	my $rch = ($finish ? '' : '-');
	$self->msg_print (($finish ? "" : "\n") . ($lch x $left) . " $label " . ($rch x $right));
}

sub msg_exit_code ($$) ### ($self, $return)
{
	my $self = shift;
	my $return = shift;
	#$self->msg_print ("exit code = $return");
	$self->msg_info_log_only ("exit code = $return");
}

sub _msg_to_log ($$) ### ($self, $text)
{
	my $self = shift;
	my $text = shift;

	my $sec, my $min, my $hour;
	my $mday, my $mon, my $year, my $wday, my $yday, my $isdst; 
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	my $date = sprintf ("%4d-%02d-%02d", $year+1900,$mon+1,$mday);
	
	my $open_success = open (my $fh, '>>', "../../../svn-bak/_logging_/hook-log_$self->{repos_base}_$date.txt");
	if ($open_success)
	{
		print $fh "$text\n";
		close ($fh);
	}
	else
	{
		#print STDERR "ERROR: logging failed.\n" if ($debugging_enabled);
	}
}

sub write_value ($$$\$) ### ($self, $fn, $text, \$return)
{
	my $self = shift; ### $_[0]
	my $fn = shift;
	my $text = shift;
	my $return = shift; ### ref

	if ( -e $fn )
	{
		$self->msg_error ("backup file <$fn> for property already exists.", $$return);
	}
	else
	{
		my $open_success = open (my $fh, '>', $fn);
		if ($open_success)
		{
			print $fh $text;
			close ($fh);
		}
		unless ( -e $fn and -s $fn )
		{
			$self->msg_error ("failed to create or write to backup file <$fn>.", $$return);
		}
	}
}

### ===========================================================================

1; ### perl module 'true' return
