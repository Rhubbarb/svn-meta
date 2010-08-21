@echo off

REM ###########################################################################
REM
REM Uniform Subversion Server Repository Hook Wrapper
REM -------------------------------------------------
REM
REM $URL$
REM $Rev$
REM
REM Copyright � 2010 Rob Hubbard.
REM
REM This file forms part of Rob Hubbard's Subversion Configuration Suite
REM (the "Software").
REM
REM Permission is hereby granted, free of charge, to any person obtaining a
REM copy of the Software and associated documentation files, to deal in the
REM Software without restriction, including without limitation the rights to
REM use, copy, modify, merge, publish, and/or distribute (free of charge)
REM copies of the Software, and to permit persons to whom the Software is
REM furnished to do so, subject to the following conditions:
REM
REM The above copyright notice and this permission notice shall be included in
REM all copies or substantial portions of the Software. For clarity, the above
REM copyright notice and this permission notice do not apply to any software
REM developed using but not incorporating the Software.
REM
REM The Software is provided "as is", without warranty of any kind, express or
REM implied, including but not limited to the warranties of merchantability,
REM fitness for a particular purpose and noninfringement. In no event shall the
REM authors or copyright holders be liable for any claim, damages or other
REM liability, whether in an action of contract, tort or otherwise, arising
REM from, out of or in connection with the Software or the use or other
REM dealings in the Software. 
REM
REM "Copyleft; All wrongs reversed."
REM
REM ###########################################################################

setlocal

cd "%~0/../../../_common_/hooks" 2>nul || ( echo ERROR: can't cd to ^<../../_common_/hooks/^> 1>&2 & exit /b 1 )

call "subroutine/prepare_environment.bat" 2>nul || ( echo ERROR: can't call ^<subroutine/prepare_environment.bat^> 1>&2 & exit /b 1 )

if not exist "%~n0.pl" ( echo ERROR: can't do perl ^<%~n0.pl^> 1>&2 & exit /b 1 )
perl "%~n0.pl" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"

if errorlevel 1 exit 1
exit 0