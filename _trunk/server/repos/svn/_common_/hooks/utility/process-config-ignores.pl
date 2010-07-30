#!/usr/bin/perl

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