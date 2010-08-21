#!/usr/bin/perl

### $URL$
### $Rev$

### ===========================================================================
### Modules to use

use strict;
use _subroutine::iterate_hooks;
use File::Copy;

### ===========================================================================

sub create ($$$)
{
	my $fn = shift;
	my $is_present = shift;
	my $want_present = shift;

	if ($want_present)
	{
		if ($is_present)
		{
			print "Wrapper $fn already exists.\n";
		}
		else
		{
			print "Creating wrapper $fn ...";
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

### ===========================================================================

iterate_hooks::iterate (&create);
