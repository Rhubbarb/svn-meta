@echo off

REM ###########################################################################
REM
REM Uniform Subversion MIRROR Server Repository Hook Wrapper
REM --------------------------------------------------------
REM
REM $URL$
REM $Rev$
REM
REM This file accompanies Rob Hubbard's Subversion Configuration Suite
REM
REM @ 2010, Rob Hubbard.
REM
REM ###########################################################################

setlocal

rem cd "%~0/../../../_common_/hooks" 2>nul || ( echo ERROR: can't cd to ^<../../_common_/hooks/^> 1>&2 & exit /b 1 )

rem call "subroutine/prepare_environment.bat" 2>nul || ( echo ERROR: can't call ^<subroutine/prepare_environment.bat^> 1>&2 & exit /b 1 )

if not exist "%~n0.pl" ( echo ERROR: can't do perl ^<%~n0.pl^> 1>&2 & exit /b 1 )
perl "%~n0.pl" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"

if errorlevel 1 exit 1
exit 0
