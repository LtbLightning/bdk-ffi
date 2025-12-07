#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Running BDK integration tests on iOS simulator..."
echo ""
echo "Make sure you have:"
echo "1. Built the iOS static library (./scripts/build_example_ios.sh)"
echo "2. Linked libbdkffi.a in Xcode (see README.md)"
echo ""

# Get simulator ID
SIMULATOR_ID=$(flutter devices | grep -E "iPhone.*simulator" | head -1 | awk '{print $4}' | tr -d '•')

if [ -z "$SIMULATOR_ID" ]; then
  echo "No iOS simulator found. Please start one from Xcode."
  exit 1
fi

echo "Using simulator: $SIMULATOR_ID"
echo ""

cd example
flutter test integration_test/bdk_test.dart -d "$SIMULATOR_ID"
