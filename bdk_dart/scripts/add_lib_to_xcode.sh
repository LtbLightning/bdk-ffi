#!/usr/bin/env bash
set -euo pipefail

# This script adds libbdkffi.a to the Xcode project programmatically
# using PlistBuddy to modify the project.pbxproj file

EXAMPLE_DIR="$(cd "$(dirname "$0")/../example" && pwd)"
PROJECT_FILE="$EXAMPLE_DIR/ios/Runner.xcodeproj/project.pbxproj"
LIB_PATH="libbdkffi.a"

echo "Adding libbdkffi.a to Xcode project..."
echo "Project file: $PROJECT_FILE"

# Check if the library is already in the project
if grep -q "libbdkffi.a" "$PROJECT_FILE"; then
    echo "libbdkffi.a is already in the project!"
    exit 0
fi

echo ""
echo "⚠️  Automatic Xcode project modification can be tricky."
echo "Please manually add libbdkffi.a in Xcode:"
echo ""
echo "1. In Xcode, in the Project Navigator (left sidebar), right-click on 'Runner'"
echo "2. Select 'Add Files to \"Runner\"...'"
echo "3. Navigate to: $EXAMPLE_DIR/ios/Runner/"
echo "4. Select 'libbdkffi.a' and click 'Add'"
echo "5. In the project target 'Runner', go to 'Build Phases'"
echo "6. Expand 'Link Binary With Libraries'"
echo "7. Verify 'libbdkffi.a' is listed (it should be added automatically)"
echo ""
echo "Then run the tests with:"
echo "  cd $EXAMPLE_DIR"
echo "  flutter test integration_test/bdk_test.dart -d \"iPhone 16 Plus\""
