@echo off
echo Fixing Google ML Kit packages namespace issues...
echo.

REM Find the correct pub cache directory
set PUB_CACHE=%LOCALAPPDATA%\Pub\Cache
if not exist "%PUB_CACHE%" set PUB_CACHE=%APPDATA%\.pub-cache
if not exist "%PUB_CACHE%" (
  echo Could not find pub cache directory.
  echo Please run: flutter pub cache dir
  echo And update this script with the correct path.
  goto end
)

echo Using pub cache: %PUB_CACHE%
echo.

REM Commons package
set COMMONS_DIR=%PUB_CACHE%\hosted\pub.dev\google_mlkit_commons-0.5.0\android
if not exist "%COMMONS_DIR%" (
  for /d %%d in ("%PUB_CACHE%\hosted\pub.dev\google_mlkit_commons-*") do set COMMONS_DIR=%%d\android
)

if exist "%COMMONS_DIR%" (
  echo Found Commons package at: %COMMONS_DIR%
  cd /d "%COMMONS_DIR%"
  
  echo Creating backup of build.gradle...
  copy build.gradle build.gradle.backup
  
  echo Writing new build.gradle file...
  (
  echo group 'com.google_mlkit_commons'
  echo version '1.0'
  echo.
  echo buildscript {
  echo     repositories {
  echo         google^(^)
  echo         mavenCentral^(^)
  echo     }
  echo.
  echo     dependencies {
  echo         classpath 'com.android.tools.build:gradle:7.3.0'
  echo     }
  echo }
  echo.
  echo rootProject.allprojects {
  echo     repositories {
  echo         google^(^)
  echo         mavenCentral^(^)
  echo     }
  echo }
  echo.
  echo apply plugin: 'com.android.library'
  echo.
  echo android {
  echo     namespace 'com.google_mlkit_commons'
  echo     compileSdkVersion 33
  echo.
  echo     defaultConfig {
  echo         minSdkVersion 21
  echo         targetSdkVersion 33
  echo     }
  echo.
  echo     compileOptions {
  echo         sourceCompatibility JavaVersion.VERSION_1_8
  echo         targetCompatibility JavaVersion.VERSION_1_8
  echo     }
  echo.
  echo     dependencies {
  echo         implementation 'com.google.android.gms:play-services-base:18.2.0'
  echo     }
  echo }
  ) > build.gradle.new
  
  move /y build.gradle.new build.gradle
  echo Google ML Kit Commons fixed successfully!
) else (
  echo Warning: Could not find Google ML Kit Commons package.
)

echo.

REM Image Labeling package
set LABELING_DIR=%PUB_CACHE%\hosted\pub.dev\google_mlkit_image_labeling-0.9.0\android
if not exist "%LABELING_DIR%" (
  for /d %%d in ("%PUB_CACHE%\hosted\pub.dev\google_mlkit_image_labeling-*") do set LABELING_DIR=%%d\android
)

if exist "%LABELING_DIR%" (
  echo Found Image Labeling package at: %LABELING_DIR%
  cd /d "%LABELING_DIR%"
  
  echo Creating backup of build.gradle...
  copy build.gradle build.gradle.backup
  
  echo Writing new build.gradle file...
  (
  echo group 'com.google_mlkit_image_labeling'
  echo version '1.0'
  echo.
  echo buildscript {
  echo     repositories {
  echo         google^(^)
  echo         mavenCentral^(^)
  echo     }
  echo.
  echo     dependencies {
  echo         classpath 'com.android.tools.build:gradle:7.3.0'
  echo     }
  echo }
  echo.
  echo rootProject.allprojects {
  echo     repositories {
  echo         google^(^)
  echo         mavenCentral^(^)
  echo     }
  echo }
  echo.
  echo apply plugin: 'com.android.library'
  echo.
  echo android {
  echo     namespace 'com.google_mlkit_image_labeling'
  echo     compileSdkVersion 33
  echo.
  echo     defaultConfig {
  echo         minSdkVersion 21
  echo         targetSdkVersion 33
  echo     }
  echo.
  echo     compileOptions {
  echo         sourceCompatibility JavaVersion.VERSION_1_8
  echo         targetCompatibility JavaVersion.VERSION_1_8
  echo     }
  echo.
  echo     dependencies {
  echo         implementation 'com.google.android.gms:play-services-base:18.2.0'
  echo         implementation 'com.google.android.gms:play-services-mlkit-image-labeling:17.0.1'
  echo     }
  echo }
  ) > build.gradle.new
  
  move /y build.gradle.new build.gradle
  echo Google ML Kit Image Labeling fixed successfully!
) else (
  echo Warning: Could not find Google ML Kit Image Labeling package.
)

:end
echo.
echo All fixes applied!
echo.
echo Please run the following commands to rebuild your project:
echo.
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.
pause 