#!/usr/bin/perl

### $URL$
### $Rev$

### ===========================================================================
### Modules to use

use strict;
use _subroutine::iterate_hooks;
use File::Compare;
use File::stat;

### ===========================================================================

sub my_compare ($$$)
{
	my $fn = shift;
	my $is_present = shift;
	my $want_present = shift;

	print "wrapper $fn :";

	if ($is_present)
	{
		my $tmpl = "_hook_template_";
		iterate_hooks::tmpl_fn ($tmpl);
		my $cmp = compare ("../_template/$tmpl", "../$fn");
		
		if ($cmp == 0)
		{
			print " identical";
		}
		elsif ($cmp == 1)
		{
			print " DIFFERENT";

			my $tmod = stat("../_template/$tmpl");
			my $fmod = stat("../$fn");

			if ($tmod < $fmod)
			{
				print " (wrapper newer)";
			}
			elsif ($tmod > $fmod)
			{
				print " (template newer)";
			}
		}
		elsif ($cmp == -1)
		{
			print " *** ERROR ***";
		}
		else
		{
			print " *** UNKNOWN ***";
		}
	}

	if ($want_present)
	{
		if ($is_present)
		{
			#print " present";
		}
		else
		{
			print " MISSING";
		}
	}
	else
	{
		if ($is_present)
		{
			print " SURPLUS";
		}
		else
		{
			#print " (unwanted)";
		}
	}

	print "\n";
}

### ===========================================================================

iterate_hooks::iterate (&my_compare);
