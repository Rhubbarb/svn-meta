#!/usr/bin/perl

###############################################################################
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

$success = open ($fh, "<", "$ARGV[0]");
if ($success)
{
	@lines = <$fh>;
	close $fh;

	%globs = ();
	foreach $line (@lines)
	{
		chomp($line);
		{
			@globs = split(/\s+/,$line);
			@globs = sort (@globs);
			for $glob (@globs)
			{
				unless ($glob ~~ /^\s*$/)
				{
					$globs{$glob} = ();
				}
			}
		}
	}

	@globs = keys (%globs);
	@globs = sort (@globs);
	print "[miscellany]\n";
	print "global-ignores =\n";
		for $glob (@globs)
	{
		print "\t$glob\n";
	}
}