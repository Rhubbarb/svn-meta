#!/usr/bin/perl

$success = open ($fh, "<", "$ARGV[0]");
if ($success)
{
	@lines = <$fh>;
	close $fh;

	foreach $line (@lines)
	{
		chomp($line);
		if ($line ~~ /^\[(.*)\]$/)
		{
			print "[$1]\n";
		}
		elsif ($line ~~ /^([^#][^=]+) = (.+)$/)
		{
			$glob = $1;
			$props = $2;
			@props = split(/;/,$props);
			@props = sort (@props);
			$props = join (";", @props);

			print "$glob = $props\n";
		}
	}
}