@echo off
REM JBoss, the OpenSource webOS
REM
REM Distributable under LGPL license.
REM See terms of license at gnu.org.
REM
REM -------------------------------------------------------------------------
REM JBoss Service Script for Windows
REM -------------------------------------------------------------------------
REM
REM Set to all parameters
rem set JBOSS_HOME=C:\jboss\jboss-eap-6.1

set SEVICE_OPTS=%*

@if "%OS%" == "Windows_NT" setlocal
set "CURRENT_DIR=%~dp0%"
set "SELF=%~dp0%service.bat"  
set "COMMONS_DAEMON_JAR=%CURRENT_DIR%%PROCRUN_JAR%"

pushd "%CURRENT_DIR%..\..\.."
set "RESOLVED_JBOSS_HOME=%CD%"
popd

if "x%JBOSS_HOME%" == "x" (
  set "JBOSS_HOME=%RESOLVED_JBOSS_HOME%"
)

pushd "%JBOSS_HOME%"
set "SANITIZED_JBOSS_HOME=%CD%"
popd

if /i "%RESOLVED_JBOSS_HOME%" NEQ "%SANITIZED_JBOSS_HOME%" (
   echo.
   echo   WARNING:  JBOSS_HOME may be pointing to a different installation - unpredictable results may occur.
   echo.
   echo             JBOSS_HOME: %JBOSS_HOME%
   echo.
   goto ErrorExit
)

REM Read an optional configuration file.
if "x%SERVICE_CONF%" == "x" (
   set "SERVICE_CONF=%CURRENT_DIR%service.conf.bat"
)
if exist "%SERVICE_CONF%" (
   echo Calling "%SERVICE_CONF%"
   call "%SERVICE_CONF%" %*
) else (
   echo Config file not found "%SERVICE_CONF%"
)

if "x%SERVICE_NAME%" == "x" (
   echo.
   echo   ERROR:    Service name not set. Cannot continue.
   echo.
   echo             Provide SERVICE_NAME environment variable or set it inside
   echo             service.conf.bar file.
   echo.
   goto ErrorExit
)

if exist "%CURRENT_DIR%%SERVICE_NAME%.exe" (
	set "SERVICE_EXEC=%CURRENT_DIR%%SERVICE_NAME%.exe"
) else (
	set "SERVICE_EXEC=%CURRENT_DIR%prunsrv.exe"
)

rem Make sure prerequisite environment variables are set
if not "x%JAVA_HOME%x" == "xx" goto HasJdkHome
if not "x%JRE_HOME%x"  == "xx" goto HasJreHome
echo. 
echo   ERROR
echo   Neither the JAVA_HOME nor the JRE_HOME environment variable is defined
echo   This environment variable is needed to run this program
echo   NB: JAVA_HOME should point to a JDK not a JRE
goto ErrorExit
:HasJreHome
if not exist "%JRE_HOME%\bin\java.exe"  goto NoJavaHome
if not exist "%JRE_HOME%\bin\javaw.exe" goto NoJavaHome
goto CheckCmdParm
:HasJdkHome
if not exist "%JAVA_HOME%\jre\bin\java.exe"  goto NoJavaHome
if not exist "%JAVA_HOME%\jre\bin\javaw.exe" goto NoJavaHome
if not exist "%JAVA_HOME%\bin\javac.exe"     goto NoJavaHome
if not "x%JRE_HOME%x" == "xx" goto CheckCmdParm
set "JRE_HOME=%JAVA_HOME%\jre"
goto CheckCmdParm
:NoJavaHome
echo.
echo   ERROR:  The JAVA_HOME environment variable is not defined correctly.
echo   This environment variable is needed to run this program
echo   NB: JAVA_HOME should point to a JDK not a JRE
goto ErrorExit

:CheckCmdParm
if "x%1x" == "xx" goto DisplayUsage
set SERVICE_CMD=%1
shift
if "x%1x" == "xx" goto CheckServiceCmd
:CheckUser
if "x%1x" == "x/userx"  goto RunAsUser
if "x%1x" == "x--userx" goto RunAsUser
set SERVICE_NAME=%1
set SERVICE_DISPLAYNAME=JBoss Enterprise Application Server %1
shift
if "x%1x" == "xx" goto CheckServiceCmd
goto CheckUser
:RunAsUser
shift
if "x%1x" == "xx" goto DisplayUsage
set SERVICE_USER=%1
shift
runas /env /savecred /user:%SERVICE_USER% "%COMSPEC% /K \"%SELF%\" %SERVICE_CMD% %SERVICE_NAME%"
goto End
:CheckServiceCmd
if /i %SERVICE_CMD% == install   goto InstallService
if /i %SERVICE_CMD% == remove    goto RemoveService
if /i %SERVICE_CMD% == uninstall goto RemoveService
echo.
echo   ERROR:    Unknown parameter "%1"
:DisplayUsage
echo.
echo   Usage:    service.bat install^|remove [service_name] [/user username]
echo.
goto ErrorExit

REM -------------------------------------------------------------------------
REM Install Service
REM -------------------------------------------------------------------------
:InstallService
echo Installing the service '%SERVICE_NAME%' ...
REM Set the server jvm from JAVA_HOME
set "PR_JVM=%JRE_HOME%\bin\server\jvm.dll"
if exist "%PR_JVM%" goto FoundJvm
REM Set the client jvm from JAVA_HOME
set "PR_JVM=%JRE_HOME%\bin\client\jvm.dll"
if exist "%PR_JVM%" goto FoundJvm
echo. 
echo   ERROR
echo   Neither the server nor client jvm.dll are found from
echo   provided JAVA_HOME or JRE_HOME environment variables.
:FoundJvm
if "x%JAVA%" == "x" (
  set "JAVA=%JRE_HOME%\bin\java.exe"
)
rem Set default module root paths
if "x%JBOSS_MODULEPATH%" == "x" (
  set  "JBOSS_MODULEPATH=%JBOSS_HOME%\modules"
)

rem Set the standalone base dir
if "x%JBOSS_BASE_DIR%" == "x" (
  set  "JBOSS_BASE_DIR=%JBOSS_HOME%\%EAP_SERVER%"
)
rem Set the standalone log dir
if "x%JBOSS_LOG_DIR%" == "x" (
  set  "JBOSS_LOG_DIR=%JBOSS_BASE_DIR%\log"
)
rem Set the standalone configuration dir
if "x%JBOSS_CONFIG_DIR%" == "x" (
  set  "JBOSS_CONFIG_DIR=%JBOSS_BASE_DIR%/configuration"
)


set "PR_INSTALL=%EXECUTABLE%"
set "PR_LOGPATH=%JBOSS_LOG_DIR%"
if not exist "%PR_LOGPATH%\" (
	echo Creating "%PR_LOGPATH%"
	mkdir "%PR_LOGPATH%"
)
set "PR_CLASSPATH=%JBOSS_HOME%\jboss-modules.jar"
set "PR_DISPLAYNAME=%SERVICE_DISP%"
set "PR_DESCRIPTION=%SERVICE_DESC%"
set PR_STDOUTPUT=auto
set PR_STDERROR=auto
REM set
"%SERVICE_EXEC%" "//IS//%SERVICE_NAME%" --StartClass org.jboss.modules.Main --StopClass java.lang.System --StopMethod exit ^
	--Startup %SERVICE_STARTUP_MODE% ^
	--StartParams "-mp;%JBOSS_MODULEPATH%;-jaxpmodule;javax.xml.jaxp-provider;%EAP_SERVER_CLASS%;-c;%EAP_SERVER_CONFIG%;"
if not errorlevel 1 goto Installed
echo.
echo Failed installing '%SERVICE_NAME%' service
goto ErrorExit

:Installed
rem Clear the environment variables. They are not needed any more.
set PR_DISPLAYNAME=
set PR_DESCRIPTION=
set PR_INSTALL=
set PR_LOGPATH=
set PR_CLASSPATH=
set PR_JVM=
set PR_STDOUTPUT=
set PR_STDERROR=
set "JAVA_OPTS=%JAVA_OPTS%;-Dorg.jboss.boot.log.file=%JBOSS_LOG_DIR%\server.log"
set "JAVA_OPTS=%JAVA_OPTS%;-Dlogging.configuration=file:%JBOSS_CONFIG_DIR%/logging.properties"
set "JAVA_OPTS=%JAVA_OPTS%;-Djboss.home.dir=%JBOSS_HOME%"
"%SERVICE_EXEC%" "//US//%SERVICE_NAME%" --JvmOptions "%JAVA_OPTS%" --JvmMs %JVM_MS% --JvmMx %JVM_MX% --StartMode jvm --StopMode jvm

echo The service '%SERVICE_NAME%' has been installed.
goto End

REM -------------------------------------------------------------------------
REM Remove Service
REM -------------------------------------------------------------------------
:RemoveService
"%SERVICE_EXEC%" "//DS//%SERVICE_NAME%"
if not errorlevel 1 goto Removed
echo.
echo Failed removing '%SERVICE_NAME%' service
goto ErrorExit

:Removed
echo The service '%SERVICE_NAME%' has been removed
goto End

:End
cd "%CURRENT_DIR%"
exit /b 0

:ErrorExit
cd "%CURRENT_DIR%"
rem 2 seconds pause
ping 127.0.0.1 -n 3 > nul
exit /b 1
