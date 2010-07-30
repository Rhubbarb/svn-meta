@echo off

REM ===========================================================================
REM *** clear environment
rem set PATH=
for /F "delims==" %%g in ('set') do set %%g=
rem set 1>&2

REM ===========================================================================
REM *** set limited environment

REM *** C:\Windows\system32;
REM *** C:\Windows;
REM *** C:\Windows\System32\Wbem;
REM *** C:\Windows\System32\WindowsPowerShell\v1.0\;

REM *** C:\strawberry\c\bin;C:\strawberry\perl\site\bin;

REM *** C:\Program Files\TortoiseSVN\bin

set PATH=C:\Program Files\SlikSvn\bin\;C:\strawberry\perl\bin

REM ===========================================================================
