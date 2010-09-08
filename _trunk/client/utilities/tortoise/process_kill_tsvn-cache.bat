@echo off

REM ###########################################################################
REM
REM TortoiseSVN Cache Resetter
REM --------------------------
REM
REM $URL$
REM $Rev$
REM
REM This file accompanies Rob Hubbard's Subversion Configuration Suite
REM
REM @ 2010, Rob Hubbard.
REM
REM ###########################################################################

echo.
taskkill /IM "TSVNCache.exe" /F /T
