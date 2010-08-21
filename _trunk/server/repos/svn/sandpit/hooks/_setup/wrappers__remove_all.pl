#!/usr/bin/perl

### $URL$
### $Rev$

### ===========================================================================
### Modules to use

use strict;
use _subroutine::iterate_hooks;
use File::Compare;
#use File::stat;

### ===========================================================================

sub remove_all ($$$)
{
	my $fn = shift;
	my $is_present = shift;
	my $want_present = shift;

	if ($is_present)
	{
		my $tmpl = "_hook_template_";
		iterate_hooks::tmpl_fn ($tmpl);
		my $cmp = compare ("../_template/$tmpl", "../$fn");
		
		if ($cmp == 0)
		{
			print "Removing $fn ...";
			if (unlink ("../$fn"))
			{
				print (" success");
			}
			else
			{
				print (" FAILURE");
			}
			print (".\n");
		}
		else
		{
			#my $tmod = stat("../_template/$tmpl");
			#my $fmod = stat("../$fn");

			print "Not removing wrapper $fn which differs from template.\n";
		}
	}
}

### ===========================================================================

iterate_hooks::iterate (&remove_all);
