#!/usr/bin/perl

###############################################################################
###
### Subversion Server Repository Hook Wrapper Quick Initialisation
### --------------------------------------------------------------
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

package iterate_hooks;

### functional iterate routine

sub fn (\$)
{
	my $fn = shift;
	$$fn .= ".bat" if $^O eq "MSWin32";
}
sub tmpl_fn (\$)
{
	my $fn = shift;
	$$fn .= ".bat" if $^O eq "MSWin32";
	$$fn .= ".sh" if $^O eq "linux";
}

sub iterate (\&) ### (callback)
{
	my $cb = shift;

	unless ( -e "selected_hooks.txt" )
	{
		print "Error : \"selected_hooks.txt\" does not exist\n";
	}
	else
	{
		my $success = open (my $fh, "<", "selected_hooks.txt");

		if ($success)
		{
			my @lines = <$fh>;
			close ($fh);
			foreach my $line (@lines)
			{
				chomp ($line);
				#print "$line\n";

				if ($line =~ /^\s*(#*)\s*([-a-z]+)\s*$/)
				{
					my $fn = $2;
					fn ($fn);

					my $is_present = ( -e "../$fn" );
					my $want_present = ($1 eq "");

					&$cb ($fn, $is_present, $want_present);
				}
			}
		}
		else
		{
			print "script error\n";
		}
	}
}

### ===========================================================================

1; ### perl module 'true' return
