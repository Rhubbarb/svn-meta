#!/usr/bin/perl

### $URL$
### $Rev$

### ===========================================================================
### Modules to use

use strict;
use _subroutine::iterate_hooks;
use File::Compare;
use File::stat;
use File::Copy;

### ===========================================================================

sub update ($$$)
{
	my $fn = shift;
	my $is_present = shift;
	my $want_present = shift;

	#if ($want_present)
	{
		if ($is_present)
		{
			my $tmpl = "_hook_template_";
			iterate_hooks::tmpl_fn ($tmpl);
			my $cmp = compare ("../_template/$tmpl", "../$fn");

			if ($cmp == 0)
			{
				print "Wrapper $fn is already identical to template.\n";
			}
			elsif ($cmp == 1)
			{
				my $tmod = stat("../_template/$tmpl");
				my $fmod = stat("../$fn");

				if ($tmod < $fmod)
				{
					print "Not updating wrapper $fn which is newer than template.\n";
				}
				elsif ($tmod > $fmod)
				{
					print "Updating wrapper $fn ...";
					my $tmpl = "_hook_template_";
					iterate_hooks::tmpl_fn ($tmpl);
					if (copy ("../_template/$tmpl", "../$fn"))
					{
						print (" success");
					}
					else
					{
						print (" FAILURE");
					}
					print (".\n");
				}
			}
		}
	}
}

### ===========================================================================

iterate_hooks::iterate (&update);
