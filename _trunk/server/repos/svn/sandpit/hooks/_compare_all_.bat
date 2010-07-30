@echo off

goto :Main

REM ===========================================================================
goto :EOF

:Compare
if "%~1" == "" (
	echo ERROR : %~nx0 / %0 : missing parameter
) else (
	fc "_hook_template_.bat.tmpl" "%~1.bat" | find "FC: no dif" > nul 
	if errorlevel 1 (
		echo ALERT: %~1.bat differs from template
	) else (
		echo okay: %~1.bat same as template
	)
)
goto :EOF

REM ===========================================================================

:Main

call :Compare "start-commit"
call :Compare "pre-commit"
call :Compare "post-commit"

call :Compare "pre-revprop-change"
call :Compare "post-revprop-change"