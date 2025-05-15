@echo off
echo Fixing Google ML Kit Commons namespace issue...

cd %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\google_mlkit_commons-0.5.0\android\

echo.
echo Creating backup of build.gradle...
copy build.gradle build.gradle.backup

echo.
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

echo.
echo Fix applied successfully!
echo Please run "flutter clean" and try building your app again.
pause 