@echo off
REM JBoss, the OpenSource webOS
REM
REM Distributable under LGPL license.
REM See terms of license at gnu.org.
REM
REM -------------------------------------------------------------------------
REM JBoss Service Script Configuration
REM -------------------------------------------------------------------------

REM
REM EAP_VERSION, EAP_VERSION_MAJOR and EAP_VERSION_MINOR are populated
REM at build time.
REM
set EAP_VERSION_MAJOR=6
set EAP_VERSION_MINOR=1
set EAP_VERSION_MICRO=0
rem set EAP_VERSION_PATCH=ER4
set EAP_VERSION=%EAP_VERSION_MAJOR%.%EAP_VERSION_MINOR%.%EAP_VERSION_MICRO%.%EAP_VERSION_PATCH%
set PROCRUN_JAR=commons-daemon-1.0.15.jar
set SERVICE_NAME=JBOSS_EAP6_SERVICE
set SERVICE_DISP=JBoss EAP 6.1.0
set SERVICE_DESC=JBoss EAP Application Server
set EAP_SERVER=standalone
set EAP_SERVER_CLASS=org.jboss.as.standalone
set EAP_SERVER_CONFIG=standalone.xml
REM Possible values for startup mode are 'manual' or 'auto'.
set SERVICE_STARTUP_MODE=auto

rem #
rem # Specify options to pass to the Java VM. Note, there are some additional
rem # options that are always passed by run.bat.
rem #

rem # JVM memory allocation pool parameters - modify as appropriate.
set "JVM_MS=-1303M"
set "JVM_MX=-1303M"
set "JAVA_OPTS=-XX:MaxPermSize=256M"

rem # Prefer IPv4
set "JAVA_OPTS=%JAVA_OPTS%;-Djava.net.preferIPv4Stack=true"

rem # Make Byteman classes visible in all module loaders
rem # This is necessary to inject Byteman rules into AS7 deployments
set "JAVA_OPTS=%JAVA_OPTS%;-Djboss.modules.system.pkgs=org.jboss.byteman"

rem # Sample JPDA settings for remote socket debugging
rem set "JAVA_OPTS=%JAVA_OPTS%;-agentlib:jdwp=transport=dt_socket,address=8787,server=y,suspend=n"

rem # Sample JPDA settings for shared memory debugging
rem set "JAVA_OPTS=%JAVA_OPTS%;-agentlib:jdwp=transport=dt_shmem,address=jboss,server=y,suspend=n"

rem # Use JBoss Modules lockless mode
rem set "JAVA_OPTS=%JAVA_OPTS%;-Djboss.modules.lockless=true"
