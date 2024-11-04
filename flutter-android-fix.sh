#!/bin/bash

# Store current directory
CURRENT_DIR=$(pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🔍 Flutter Android Build Environment Diagnostic Tool"
echo "================================================="

# Check Java version
echo -e "\n📎 Checking Java version..."
java -version 2>&1 || echo -e "${RED}Java not found!${NC}"

# Check Gradle version
echo -e "\n📎 Checking Gradle version..."
if [ -f "$CURRENT_DIR/android/gradlew" ]; then
    ./android/gradlew --version || echo -e "${RED}Gradle wrapper error!${NC}"
else
    echo -e "${RED}Gradle wrapper not found!${NC}"
fi

# Check Flutter doctor
echo -e "\n📎 Running Flutter doctor..."
flutter doctor -v

# Clean build files
echo -e "\n🧹 Cleaning project..."
flutter clean
cd android
./gradlew clean
cd ..

# Update dependencies
echo -e "\n📦 Updating dependencies..."
flutter pub get

# Check Kotlin version in build.gradle
echo -e "\n📎 Checking Kotlin version in build.gradle..."
KOTLIN_VERSION=$(grep "ext.kotlin_version" android/build.gradle | cut -d "'" -f 2)
echo "Current Kotlin version: $KOTLIN_VERSION"

# Recommended versions
echo -e "\n✅ Recommended compatible versions:"
echo "Java: 11 or 17"
echo "Kotlin: 1.7.10"
echo "Gradle: 7.5.1"
echo "Android Gradle Plugin: 7.3.0"

# Generate version fix suggestions
echo -e "\n🛠️ Suggested fixes for build.gradle:"
cat << EOF
// In android/build.gradle:
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:\$kotlin_version"
    }
}

// In android/gradle/wrapper/gradle-wrapper.properties:
distributionUrl=https\://services.gradle.org/distributions/gradle-7.5.1-all.zip
EOF

# Check for common error patterns in build logs
echo -e "\n🔍 Checking for common error patterns..."
if [ -f "android/build.gradle" ]; then
    if grep -q "kotlin_version" android/build.gradle; then
        echo -e "${GREEN}✓ Kotlin version is defined in build.gradle${NC}"
    else
        echo -e "${RED}✗ Kotlin version not found in build.gradle${NC}"
    fi
fi

# Provide instructions
echo -e "\n📝 To fix compatibility issues:"
echo "1. Update Java version:"
echo "   sudo update-alternatives --config java"
echo ""
echo "2. Update Kotlin plugin in Android Studio:"
echo "   - Go to Settings > Plugins"
echo "   - Update Kotlin plugin to version matching build.gradle"
echo ""
echo "3. Update Gradle wrapper:"
echo "   ./android/gradlew wrapper --gradle-version 7.5.1"
echo ""
echo "4. Sync project with Gradle files in Android Studio"
echo ""
echo "5. Run Flutter clean and rebuild:"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter run"

# Final check
echo -e "\n🔄 Running final validation..."
flutter build apk --debug

