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

package common;

my $logging_enabled = 1;
my $debugging_enabled = 0;

### ===========================================================================
# Declarations of Functions

# Perl trim function to remove whitespace from the start and end of the string
sub trim ($); ### ($string)

sub default_int ($$); ### ($str, $default)

sub safe_name ($); ### ($fn)

### ===========================================================================
# Declarations of Methods

### NB: prototypes not actually enforced for method calls

sub msg_print ($$); ### ($self, $text)
sub msg_info_log_only ($$); ### ($self, $text)
sub msg_error ($$\$); ### ($self, $text, \$return)
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

sub safe_name ($) ### ($fn)
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

### ===========================================================================
# Definitions of Methods

sub spawn ($$) ### ($class, $hook, $repos)
{
	my $class = shift;
	my $hook = shift;
	my $repos = shift;

	(my $repos_base = $repos) =~ s(^.*[\/\\])();

	my $self =
	{
		'hook' => $hook,
		'repos' => $repos,
		'repos_base' => $repos_base,
	};
	bless ($self, $class);
	return $self;
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

sub msg_now_banner($$$) ### ($self, $end, $return)
{
	my $self = shift;
	my $end = shift;

	my $sec, my $min, my $hour;
	my $mday, my $mon, my $year, my $wday, my $yday, my $isdst; 
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	my $now = sprintf ("%4d-%02d-%02dT%02d:%02d:%02dZ", $year+1900,$mon+1,$mday,$hour,$min,$sec);

	(my $repos_base = $repos) =~ s(^.*[\/\\])();
	my $label = ($end ? "finish" : "$self->{repos_base} $self->{hook} start") . " $now";
	my $len = length($label);
	my $to_pad = 79 - 2 - $len;
	my $left = int ($to_pad / 2);
	my $right = $to_pad - $left;
	#print STDERR "$len, $to_pad, $left, $right\n";
	my $ch = ($end ? "_" : "^");
	$self->msg_print (($end ? "" : "\n") . ($ch x $left) . " $label " . ($ch x $right));
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
