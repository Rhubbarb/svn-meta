@echo off

goto :Main

REM ===========================================================================
goto :EOF

REM ---------------------------------------------------------------------------
:CreateService
sc create svnserve ^
  binpath= "\"C:\Program Files\SlikSvn\bin\svnserve.exe\" --service --root C:\Rob\version_controlled\repos\svn --listen-host 0.0.0.0" ^
  displayname= "Subversion" ^
  depend= Tcpip ^
  start= auto ^
  obj= "NT AUTHORITY\LocalService"
rem sc description svnserve "Subversion Server (svnserve)"
goto :EOF

rem for --listen-host 0.0.0.0
rem see http://groups.google.com/group/tortoisesvn/browse_thread/thread/9e31eeff7850b9b2?pli=1
rem IPv6 versus IPv4

REM ---------------------------------------------------------------------------
:DeleteService
sc delete svnserve
goto :EOF
  
REM ---------------------------------------------------------------------------
:StartService
net start svnserve
goto :EOF

REM ---------------------------------------------------------------------------
:StopService
net stop svnserve
goto :EOF
  
REM ===========================================================================
:Main

if "%~1" == "stop" call :StopService
if "%~1" == "del" call :DeleteService
if "%~1" == "add" call :CreateService
if "%~1" == "start" call :StartService
