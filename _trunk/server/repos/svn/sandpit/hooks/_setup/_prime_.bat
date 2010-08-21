@echo off
setlocal

goto :Main

REM ===========================================================================

goto :EOF

REM ---------------------------------------------------------------------------
REM *** Copy Template

:CopyTmpl
if "%~1" == "" (
	echo Error : %~nx0 / %0 : missing parameter
) else (
	rem echo %~1.tmpl %~1
	if exist "%~1" (
		echo Note : %~1 already exists
	) else (
		if not exist "%~1.tmpl" (
			echo Error : %~1.tmpl not found
		) else (
			echo Creating %~1 ...
			copy "%~1.tmpl" "%~1"
		)
	)
)
goto :EOF

REM ---------------------------------------------------------------------------
REM *** Copy Templates

:CopyTmpls
for %%G in (*.tmpl) do (
	set GG=%%G
	rem echo %%G
	rem echo %GG% %GG:.tmpl=%
	call :CopyTmpl %GG:.tmpl=%
)
goto :EOF

REM ===========================================================================

:Main

REM this doesn't work when run from the icon
rem call :CopyTmpls

call :CopyTmpl selected_hooks.txt

rem pause
