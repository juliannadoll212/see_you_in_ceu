@echo off
echo Fixing Google ML Kit packages namespace issues...
echo.

REM Fix Google ML Kit Commons
echo Fixing Google ML Kit Commons...
cd %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\google_mlkit_commons-0.5.0\android\

if exist build.gradle (
    echo Creating backup of build.gradle...
    copy build.gradle build.gradle.backup

    echo Updating build.gradle to include namespace...
    (
    echo group 'com.google_mlkit_commons'
    echo version '1.0'
    echo.
    echo buildscript {
    echo     repositories {
    echo         google()
    echo         mavenCentral()
    echo     }
    echo.
    echo     dependencies {
    echo         classpath 'com.android.tools.build:gradle:7.3.0'
    echo     }
    echo }
    echo.
    echo rootProject.allprojects {
    echo     repositories {
    echo         google()
    echo         mavenCentral()
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
    echo Warning: Could not find Google ML Kit Commons build.gradle
)

echo.

REM Fix Google ML Kit Image Labeling
echo Fixing Google ML Kit Image Labeling...
cd %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\google_mlkit_image_labeling-0.9.0\android\

if exist build.gradle (
    echo Creating backup of build.gradle...
    copy build.gradle build.gradle.backup

    echo Updating build.gradle to include namespace...
    (
    echo group 'com.google_mlkit_image_labeling'
    echo version '1.0'
    echo.
    echo buildscript {
    echo     repositories {
    echo         google()
    echo         mavenCentral()
    echo     }
    echo.
    echo     dependencies {
    echo         classpath 'com.android.tools.build:gradle:7.3.0'
    echo     }
    echo }
    echo.
    echo rootProject.allprojects {
    echo     repositories {
    echo         google()
    echo         mavenCentral()
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
    echo Warning: Could not find Google ML Kit Image Labeling build.gradle
)

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