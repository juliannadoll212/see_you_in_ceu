@echo off
echo Running Gradle with Java 24...
set JAVA_HOME=C:\Program Files\Java\jdk-24
set PATH=%JAVA_HOME%\bin;%PATH%
set GRADLE_OPTS=-Dorg.gradle.jvmargs="-Xmx4096M -Dfile.encoding=UTF-8 --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.base/java.util=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED"

echo Java version:
java -version

echo Running Gradle with command: %*
.\gradlew %* --warning-mode all --stacktrace 