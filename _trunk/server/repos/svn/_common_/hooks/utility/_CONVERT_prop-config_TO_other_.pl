#!/usr/bin/perl

###############################################################################
###
### Subversion Server to Client Property Configuration Converter
### ------------------------------------------------------------
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

if (1)
{

	### ===================================================================
	### Parse the hook property configuration file

	$success = open ($fh, '<', "../hook_config/prop-config.txt");
	if ($success)
	{
		@config_lines = <$fh>;
		$linenum = 0;
		@globs = ();
		$all_props = {};
		foreach $line (@config_lines)
		{
			++ $linenum;
			chomp ($line);
			if ($line ~~ /^\s*$/ or $line ~~ /^\s*\#/)
			{
				### ignore the line
			}
			elsif ($line ~~ /^\s*g\s*<\s*(.*)\s*>\s*$/)
			{
				@globs = split (/\s+/, $1);
			}
			elsif ($line ~~ /^\s*([+=-])\s*([^=]*[^=\s])\s*=\s*(.*[^\s])\s*$/)
			{
				$required = ($1 eq "+");
				$prohibited = ($1 eq "-");
				$prop_name = $2;
				$prop_value = $3;
				foreach $glob (@globs)
				{
					$property_config{$glob}{$prop_name} = [$required, $prohibited, $prop_value];
				}
				$all_props{$prop_name} = ();
			}
			elsif ($line ~~ /^\s*([+=-])\s*(.*[^\s])\s*$/)
			{
				$required = ($1 eq "+");
				$prohibited = ($1 eq "-");
				$prop_name = $2;
				foreach $glob (@globs)
				{
					$property_config{$glob}{$prop_name} = [$required, $prohibited, ()];
				}
				$all_props{$prop_name} = ();
			}
			else
			{
				print STDERR "ERROR: bad line $linenum in property configuration file.\n";
				$return = 1;
			}
		}
		close ($fh);
	}
	else
	{
		print STDERR "ERROR: could not find or read property configuration file.\n";
		$return = 1;
	}

	### ===================================================================
	### Output a fragment of an SVN <config> file

	### optional values shown commented

	$success &&= open ($fh, '>', "./config.auto-props.stdout.txt");
	if ($success)
	{
		print $fh "\n";
		print $fh "[miscellany]\n";
		print $fh "enable-auto-props = yes\n";
		print $fh "\n";
		print $fh "[auto-props]\n";

		@globs = keys(%property_config);
		@globs = sort(@globs);
		foreach $glob (@globs)
		{
			%propvals = %{$property_config{$glob}};
			@props = keys(%propvals);
			@props = sort(@props);
			@prop_strs = ();
			@prop_opt_strs = ();
			foreach $prop_name (@props)
			{
				$entry = $propvals{$prop_name};
				$prop_value_specified = $entry->[2];
				#print "$glob = $prop_name = $prop_value_specified\n";

				#special_filter ($prop_name, \$prop_value_specified);
				$required = $entry->[0];
				$prohibited = $entry->[1];
				
				if ($required)
				{
					if ($prop_value_specified)
					{
						@prop_strs = (@prop_strs, "$prop_name=$prop_value_specified");
					}
					else
					{
						@prop_strs = (@prop_strs, "$prop_name");
					}
				}
				elsif (not $prohibited)
				{
					if ($prop_value_specified)
					{
						@prop_opt_strs = (@prop_opt_strs, "$prop_name=$prop_value_specified");
					}
					else
					{
						@prop_opt_strs = (@prop_opt_strs, "$prop_name");
					}
				}
			}
			if (@prop_strs)
			{
				$prop_str = join(';', @prop_strs);
				print $fh "$glob = $prop_str\n";
			}
			if (@prop_opt_strs)
			{
				$prop_opt_str = join(';', @prop_opt_strs);
				print $fh "#$glob = $prop_opt_str\n";
			}
		}

		close ($fh);
	}

	### ===================================================================
	### Output a CSV presentation of the property settings

	### optional valued in [brackets]

	### (no coding for contained commas or escaped quotes)

	$success &&= open ($fh, '>', "./config.auto-props.csv");
	if ($success)
	{
		@all_props = keys(%all_props);
		@all_props = sort(@all_props);

		$first_prop = 1;
		$props_str = "glob, = ,";
		foreach $prop_name (@all_props)
		{
			$props_str .= ",;," unless $first_prop;
			$props_str .= $prop_name;
			$first_prop = 0;
		}
		print $fh "$props_str\n";

		@globs = keys(%property_config);
		@globs = sort(@globs);
		foreach $glob (@globs)
		{
			$first_prop = 1;
			$some_prop = 0;
			$props_str = "$glob, = ,";
			%propvals = %{$property_config{$glob}};
			foreach $prop_name (@all_props)
			{
				$entry = $propvals{$prop_name};
				if ($entry)
				{
					$prop_value_specified = $entry->[2];

					$required = $entry->[0];
					$prohibited = $entry->[1];
					
					unless ($prohibited)
					{
						if ($prop_value_specified)
						{
							$prop_str = "$prop_name=$prop_value_specified";
						}
						else
						{
							$prop_str = "$prop_name";
						}
						
						$props_str .= "," unless $first_prop;
						$props_str .= ";" if $some_prop;
						$props_str .= "," unless $first_prop;
						$props_str .= "[" unless $required;
						$props_str .= $prop_str;
						$props_str .= "]" unless $required;
						
						$some_prop = 1;
					}
					else
					{
						$props_str .= ",," unless $first_prop;
					}
				}
				else
				{
					$props_str .= ",," unless $first_prop;
				}
				$first_prop = 0;
			}
			print $fh "$props_str\n";
		}

		close ($fh);
	}

	### ===================================================================
	### Output a HTML table presentation of the property settings

	### optional valued in <em>italics</em>

	### (no coding for contained commas or escaped quotes)

	$success &&= open ($fh, '>', "./config.auto-props.html");
	if ($success)
	{
		@all_props = keys(%all_props);
		@all_props = sort(@all_props);

		print $fh "<html>\n";
		print $fh "<head>\n";
		print $fh "<style type=\"text/css\">\n";
		print $fh "table\n";
		print $fh "{\n";
		print $fh "border: solid black 2px;\n";
		print $fh "border-collapse: collapse;\n";
		print $fh "}\n";
		print $fh "th\n";
		print $fh "{\n";
		print $fh "border: solid black 1px;\n";
		print $fh "background-color: lightgray;\n";
		print $fh "text-align: left;\n";
		print $fh "}\n";
		print $fh "td\n";
		print $fh "{\n";
		print $fh "border: solid gray 1px;\n";
		#print $fh "padding: 0;\n";
		#print $fh "font-size: 8pt;\n";
		print $fh "}\n";
		print $fh "td.optional\n";
		print $fh "{\n";
		print $fh "color: gray;\n";
		print $fh "font-style: italic;\n";
		print $fh "}\n";
		print $fh "</style>\n";
		print $fh "</head>\n";
		print $fh "<body>\n";
		print $fh "<table>\n";

		$first_prop = 1;
		$props_cells = "<th><em>glob</em></th><th> = </th>";
		foreach $prop_name (@all_props)
		{
			$props_cells .= "<th>;</th>" unless $first_prop;
			$props_cells .= "<th>$prop_name</th>";
			$first_prop = 0;
		}
		print $fh "<tr>$props_cells</tr>\n";

		@globs = keys(%property_config);
		@globs = sort(@globs);
		foreach $glob (@globs)
		{
			$first_prop = 1;
			$some_prop = 0;
			$props_cells = "<th>$glob</th><td> = </td>";
			%propvals = %{$property_config{$glob}};
			foreach $prop_name (@all_props)
			{
				$entry = $propvals{$prop_name};
				if ($entry)
				{
					$prop_value_specified = $entry->[2];

					$required = $entry->[0];
					$prohibited = $entry->[1];
					
					unless ($prohibited)
					{
						if ($prop_value_specified)
						{
							$prop_str = "$prop_name=$prop_value_specified";
						}
						else
						{
							$prop_str = "$prop_name";
						}
						
						$props_cells .= "<td>" unless $first_prop;
						$props_cells .= ";" if $some_prop;
						$props_cells .= "</td>" unless $first_prop;
						$props_cells .= "<td";
						$props_cells .= " class=\"optional\"" unless $required;
						$props_cells .= ">";
						$props_cells .= $prop_str;
						$props_cells .= "</td>";
						
						$some_prop = 1;
					}
					else
					{
						$props_cells .= "<td></td>" unless $first_prop;
						$props_cells .= "<td></td>";
					}
				}
				else
				{
					$props_cells .= "<td></td>" unless $first_prop;
					$props_cells .= "<td></td>";
				}
				$first_prop = 0;
			}
			print $fh "<tr>$props_cells</tr>\n";
		}

		print $fh "</table>\n";
		print $fh "</body>\n";
		print $fh "</html>\n";

		close ($fh);
	}

	### ===================================================================

}
