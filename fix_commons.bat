@echo off
setlocal enabledelayedexpansion

echo Running Google ML Kit Commons namespace fix

REM Find the pub cache directory
for /f "tokens=*" %%i in ('flutter pub cache dir') do set PUB_CACHE=%%i
echo Pub cache directory: %PUB_CACHE%

REM Find the commons package path
set COMMONS_PATTERN=%PUB_CACHE%\hosted\pub.dev\google_mlkit_commons-*\android
echo Looking for: %COMMONS_PATTERN%

for /d %%d in (%COMMONS_PATTERN%) do (
  echo Found at: %%d
  cd /d "%%d"
  
  if exist build.gradle (
    echo Creating backup of build.gradle
    copy build.gradle build.gradle.bak
    
    echo Writing new build.gradle
    
    type nul > build.gradle
    echo group 'com.google_mlkit_commons' >> build.gradle
    echo version '1.0' >> build.gradle
    echo. >> build.gradle
    echo buildscript { >> build.gradle
    echo     repositories { >> build.gradle
    echo         google() >> build.gradle
    echo         mavenCentral() >> build.gradle
    echo     } >> build.gradle
    echo. >> build.gradle
    echo     dependencies { >> build.gradle
    echo         classpath 'com.android.tools.build:gradle:7.3.0' >> build.gradle
    echo     } >> build.gradle
    echo } >> build.gradle
    echo. >> build.gradle
    echo rootProject.allprojects { >> build.gradle
    echo     repositories { >> build.gradle
    echo         google() >> build.gradle
    echo         mavenCentral() >> build.gradle
    echo     } >> build.gradle
    echo } >> build.gradle
    echo. >> build.gradle
    echo apply plugin: 'com.android.library' >> build.gradle
    echo. >> build.gradle
    echo android { >> build.gradle
    echo     namespace 'com.google_mlkit_commons' >> build.gradle
    echo     compileSdkVersion 33 >> build.gradle
    echo. >> build.gradle
    echo     defaultConfig { >> build.gradle
    echo         minSdkVersion 21 >> build.gradle
    echo         targetSdkVersion 33 >> build.gradle
    echo     } >> build.gradle
    echo. >> build.gradle
    echo     compileOptions { >> build.gradle
    echo         sourceCompatibility JavaVersion.VERSION_1_8 >> build.gradle
    echo         targetCompatibility JavaVersion.VERSION_1_8 >> build.gradle
    echo     } >> build.gradle
    echo. >> build.gradle
    echo     dependencies { >> build.gradle
    echo         implementation 'com.google.android.gms:play-services-base:18.2.0' >> build.gradle
    echo     } >> build.gradle
    echo } >> build.gradle
    
    echo Commons package fixed successfully!
  ) else (
    echo build.gradle not found in %%d
  )
)

echo Fix completed, please run: flutter clean
pause 