@echo off

rem $repos = $ARGV[0];
rem $revision = $ARGV[1];
rem $user = $ARGV[2];
rem $propname = $ARGV[3];
rem $action = $ARGV[4]; ### 'A'dded, 'M'odified, or 'D'eleted
rem $old_value = <STDIN>;

echo BEGIN test.bat

echo "Old value" | ^
call "post-revprop-change.bat" ^
	"C:\Rob\version_controlled\repos\svn\sandpit" ^
	"1" ^
	"TestScript" ^
	"svn:log" ^
	"M"

echo FINISH test.bat