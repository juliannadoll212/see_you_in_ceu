@echo off
echo Building Android APK directly...

echo Cleaning previous builds...
call gradlew clean

echo Building debug APK...
call gradlew assembleDebug --info

echo Verifying build outputs...
if exist "app\build\outputs\apk\debug\app-debug.apk" (
    echo APK build successful!
    echo Copying to expected Flutter locations...
    
    if not exist "..\build\app\outputs\apk\debug" mkdir "..\build\app\outputs\apk\debug"
    if not exist "..\build\app\outputs\flutter-apk" mkdir "..\build\app\outputs\flutter-apk"
    
    copy /Y "app\build\outputs\apk\debug\app-debug.apk" "..\build\app\outputs\apk\debug\app-debug.apk"
    copy /Y "app\build\outputs\apk\debug\app-debug.apk" "..\build\app\outputs\flutter-apk\app-debug.apk"
    
    echo Build artifacts copied successfully!
) else (
    echo ERROR: APK build failed! Check the logs above for details.
    exit /b 1
) 