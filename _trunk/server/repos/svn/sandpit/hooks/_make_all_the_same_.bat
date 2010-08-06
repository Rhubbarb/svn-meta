@echo off

setlocal

REM $URL$
REM $Rev$

goto :Main

REM ===========================================================================

goto :EOF

REM ---------------------------------------------------------------------------
REM *** Copy ***

:Copy
if "%~1" == "" (
	echo Error : %~nx0/%0 : missing parameter
) else (
	if exist "%~1.bat" (
		echo overwriting "%~1.bat" ...
		copy "_hook_template_.bat.tmpl" "%~1.bat"
	) else (
		echo no "%~1.bat" to overwrite
	)
)
goto :EOF

REM ===========================================================================

:Main

call :Copy "start-commit"
call :Copy "pre-commit"
call :Copy "post-commit"

call :Copy "pre-revprop-change"
call :Copy "post-revprop-change"
