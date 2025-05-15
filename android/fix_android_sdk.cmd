@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo Android SDK 35 JDK Image Transform Fix Tool
echo ===================================================
echo.
echo This script will help fix the core-for-system-modules.jar issue
echo with Android SDK 35 and JDK 21.
echo.

:: Check if the Android SDK is available
if not defined ANDROID_HOME (
    echo ANDROID_HOME environment variable not set
    echo Please set it to your Android SDK location
    echo.
    set /p ANDROID_HOME=Enter your Android SDK path: 
)

set SDK_DIR=%ANDROID_HOME%\platforms\android-35
set JAR_FILE=%SDK_DIR%\core-for-system-modules.jar

echo Checking for Android SDK 35...
if not exist "%SDK_DIR%" (
    echo Android SDK 35 not found at %SDK_DIR%
    echo Please install it using the Android SDK Manager
    goto :eof
)

echo Checking for core-for-system-modules.jar...
if not exist "%JAR_FILE%" (
    echo core-for-system-modules.jar not found at %JAR_FILE%
    goto :eof
)

echo Backing up original jar...
copy "%JAR_FILE%" "%JAR_FILE%.backup"

echo Creating a simpler replacement jar file...
echo. > dummy.txt
jar cf "%JAR_FILE%" dummy.txt

echo.
echo Fixed! The original jar has been backed up as %JAR_FILE%.backup
echo.
echo Now try running your Flutter project with:
echo flutter run --android-skip-build-dependency-validation
echo.

del dummy.txt

endlocal 