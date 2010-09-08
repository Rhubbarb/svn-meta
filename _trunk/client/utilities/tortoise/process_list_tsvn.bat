@echo off

REM ###########################################################################
REM
REM TortoiseSVN Process Lister
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
tasklist | findstr "Tortoise TSVN"
