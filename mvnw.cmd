@ECHO OFF
SETLOCAL

SET BASE_DIR=%~dp0
IF "%BASE_DIR:~-1%"=="\" SET BASE_DIR=%BASE_DIR:~0,-1%

SET WRAPPER_DIR=%BASE_DIR%\.mvn\wrapper
SET WRAPPER_PROPERTIES=%WRAPPER_DIR%\maven-wrapper.properties
SET WRAPPER_JAR=%WRAPPER_DIR%\maven-wrapper.jar
SET JAVA_VERSION_FILE=%BASE_DIR%\.mvn\java-version

IF NOT EXIST "%WRAPPER_PROPERTIES%" (
  ECHO Missing %WRAPPER_PROPERTIES% 1>&2
  EXIT /B 1
)

IF NOT EXIST "%WRAPPER_JAR%" (
  FOR /F "usebackq tokens=1,* delims==" %%A IN ("%WRAPPER_PROPERTIES%") DO (
    IF "%%A"=="wrapperUrl" SET WRAPPER_URL=%%B
  )

  IF "%WRAPPER_URL%"=="" (
    ECHO wrapperUrl is not configured in %WRAPPER_PROPERTIES% 1>&2
    EXIT /B 1
  )

  IF NOT EXIST "%WRAPPER_DIR%" MKDIR "%WRAPPER_DIR%"
  ECHO Downloading Maven wrapper jar from %WRAPPER_URL%
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing '%WRAPPER_URL%' -OutFile '%WRAPPER_JAR%'" || EXIT /B 1
)

IF DEFINED JAVA_HOME (
  SET JAVA_CMD=%JAVA_HOME%\bin\java.exe
) ELSE (
  IF EXIST "%JAVA_VERSION_FILE%" (
    SET /P REQUESTED_JAVA_VERSION=<"%JAVA_VERSION_FILE%"
    CALL :FindJavaHome "%REQUESTED_JAVA_VERSION%"
    IF DEFINED AUTO_JAVA_HOME (
      SET JAVA_HOME=%AUTO_JAVA_HOME%
      SET JAVA_CMD=%JAVA_HOME%\bin\java.exe
      ECHO Using JAVA_HOME=%JAVA_HOME% from .mvn\java-version
    ) ELSE (
      ECHO JDK %REQUESTED_JAVA_VERSION% is required by .mvn\java-version but was not found on this machine. 1>&2
      ECHO Install JDK %REQUESTED_JAVA_VERSION% or set JAVA_HOME explicitly. 1>&2
      EXIT /B 1
    )
  ) ELSE (
    SET JAVA_CMD=java.exe
  )
)

IF EXIST "%JAVA_VERSION_FILE%" (
  FOR /F "tokens=3" %%V IN ('"%JAVA_CMD%" -version 2^>^&1 ^| findstr /I "version"') DO (
    SET RAW_JAVA_VERSION=%%~V
    GOTO :ResolveJavaVersion
  )
  :ResolveJavaVersion
  SET RAW_JAVA_VERSION=%RAW_JAVA_VERSION:"=%
  FOR /F "tokens=1,2 delims=.-" %%A IN ("%RAW_JAVA_VERSION%") DO (
    IF "%%A"=="1" (
      SET ACTUAL_JAVA_VERSION=%%B
    ) ELSE (
      SET ACTUAL_JAVA_VERSION=%%A
    )
  )
  IF NOT "%ACTUAL_JAVA_VERSION%"=="%REQUESTED_JAVA_VERSION%" (
    ECHO JDK %REQUESTED_JAVA_VERSION% is required by .mvn\java-version but the wrapper resolved Java %ACTUAL_JAVA_VERSION%. 1>&2
    IF DEFINED JAVA_HOME ECHO Current JAVA_HOME=%JAVA_HOME% 1>&2
    ECHO Install JDK %REQUESTED_JAVA_VERSION% or set JAVA_HOME to a matching installation. 1>&2
    EXIT /B 1
  )
)

"%JAVA_CMD%" "-Dmaven.multiModuleProjectDirectory=%BASE_DIR%" -classpath "%WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %*
EXIT /B %ERRORLEVEL%

:FindJavaHome
SET AUTO_JAVA_HOME=
IF EXIST "C:\Program Files\Java\jdk-%~1" SET AUTO_JAVA_HOME=C:\Program Files\Java\jdk-%~1
IF EXIST "C:\Program Files\Eclipse Adoptium\jdk-%~1" SET AUTO_JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-%~1
IF EXIST "C:\Program Files\Microsoft\jdk-%~1" SET AUTO_JAVA_HOME=C:\Program Files\Microsoft\jdk-%~1
EXIT /B 0
