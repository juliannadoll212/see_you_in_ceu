@echo off
setlocal enabledelayedexpansion

echo Patching flutter_local_notifications plugin...

set "PLUGIN_DIR=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\flutter_local_notifications-9.1.5\android"
set "BUILD_GRADLE=%PLUGIN_DIR%\build.gradle"

echo Plugin directory: %PLUGIN_DIR%

if not exist "%PLUGIN_DIR%" (
    echo Plugin directory not found!
    echo Please run 'flutter pub get' and try again.
    goto :error
)

if not exist "%BUILD_GRADLE%" (
    echo build.gradle not found!
    goto :error
)

echo Creating backup of original build.gradle...
copy "%BUILD_GRADLE%" "%BUILD_GRADLE%.bak"
echo Backup created at: %BUILD_GRADLE%.bak

echo Patching build.gradle file...

:: Read the original file
set "content="
for /f "tokens=1* delims=:" %%a in ('findstr /n "^" "%BUILD_GRADLE%"') do (
    set "line=%%b"
    
    :: Add namespace after 'android {' line
    if "!line!" == "android {" (
        set "content=!content!!line!
    namespace 'com.dexterous.flutterlocalnotifications'"
    ) else (
        set "content=!content!!line!
"
    )
)

:: Write the modified content back to the file (simplified for this example)
echo group 'com.dexterous.flutterlocalnotifications' > "%BUILD_GRADLE%.new"
echo version '1.0-SNAPSHOT' >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo buildscript { >> "%BUILD_GRADLE%.new"
echo     repositories { >> "%BUILD_GRADLE%.new"
echo         google() >> "%BUILD_GRADLE%.new"
echo         mavenCentral() >> "%BUILD_GRADLE%.new"
echo     } >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo     dependencies { >> "%BUILD_GRADLE%.new"
echo         classpath 'com.android.tools.build:gradle:7.3.1' >> "%BUILD_GRADLE%.new"
echo     } >> "%BUILD_GRADLE%.new"
echo } >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo rootProject.allprojects { >> "%BUILD_GRADLE%.new"
echo     repositories { >> "%BUILD_GRADLE%.new"
echo         google() >> "%BUILD_GRADLE%.new"
echo         mavenCentral() >> "%BUILD_GRADLE%.new"
echo     } >> "%BUILD_GRADLE%.new"
echo } >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo apply plugin: 'com.android.library' >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo android { >> "%BUILD_GRADLE%.new"
echo     namespace 'com.dexterous.flutterlocalnotifications' >> "%BUILD_GRADLE%.new"
echo     compileSdkVersion 33 >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo     defaultConfig { >> "%BUILD_GRADLE%.new"
echo         minSdkVersion 16 >> "%BUILD_GRADLE%.new"
echo         testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner" >> "%BUILD_GRADLE%.new"
echo     } >> "%BUILD_GRADLE%.new"
echo     lintOptions { >> "%BUILD_GRADLE%.new"
echo         disable 'InvalidPackage' >> "%BUILD_GRADLE%.new"
echo     } >> "%BUILD_GRADLE%.new"
echo } >> "%BUILD_GRADLE%.new"
echo. >> "%BUILD_GRADLE%.new"
echo dependencies { >> "%BUILD_GRADLE%.new"
echo     implementation 'androidx.core:core:1.3.0' >> "%BUILD_GRADLE%.new"
echo     implementation 'androidx.localbroadcastmanager:localbroadcastmanager:1.0.0' >> "%BUILD_GRADLE%.new"
echo     implementation 'androidx.media:media:1.1.0' >> "%BUILD_GRADLE%.new"
echo     implementation 'com.google.code.gson:gson:2.8.6' >> "%BUILD_GRADLE%.new"
echo     testImplementation 'junit:junit:4.13' >> "%BUILD_GRADLE%.new"
echo     testImplementation 'org.mockito:mockito-core:3.4.0' >> "%BUILD_GRADLE%.new"
echo     testImplementation 'androidx.test:core:1.2.0' >> "%BUILD_GRADLE%.new"
echo     testImplementation 'org.robolectric:robolectric:4.3.1' >> "%BUILD_GRADLE%.new"
echo } >> "%BUILD_GRADLE%.new"

echo Moving new file to replace original...
move /y "%BUILD_GRADLE%.new" "%BUILD_GRADLE%"

echo Patch applied successfully!
echo.
echo Now run the following commands:
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.
goto :end

:error
echo An error occurred during the patching process.
echo Please try again or manually add the namespace to the build.gradle file.

:end
endlocal 