#!/usr/bin/env bash
set -euo pipefail

echo "Building BDK FFI for iOS..."

cd ../bdk-ffi

# Add iOS targets if not already installed
echo "Adding iOS targets..."
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

# Build for iOS device (arm64)
echo "Building for iOS device (aarch64)..."
cargo build --release --target aarch64-apple-ios

# Build for iOS simulator (Intel)
echo "Building for iOS simulator (x86_64)..."
cargo build --release --target x86_64-apple-ios

# Build for iOS simulator (Apple Silicon)
echo "Building for iOS simulator (aarch64)..."
cargo build --release --target aarch64-apple-ios-sim

# Create output directory
mkdir -p ../bdk_dart/ios/Frameworks

# Create XCFramework
echo "Creating XCFramework..."

# First, create fat library for simulators (combining x86_64 and aarch64 sim)
echo "Creating simulator fat library..."
lipo -create \
  ./target/x86_64-apple-ios/release/libbdkffi.a \
  ./target/aarch64-apple-ios-sim/release/libbdkffi.a \
  -output ./target/libbdkffi-sim.a

# Create XCFramework with both device and simulator
xcodebuild -create-xcframework \
  -library ./target/aarch64-apple-ios/release/libbdkffi.a \
  -headers ./dart/lib/ \
  -library ./target/libbdkffi-sim.a \
  -headers ./dart/lib/ \
  -output ../bdk_dart/ios/Frameworks/BdkFFI.xcframework

echo "✅ XCFramework created at: bdk_dart/ios/Frameworks/BdkFFI.xcframework"
echo ""
echo "Next steps:"
echo "1. Open your iOS project: open ios/Runner.xcworkspace"
echo "2. In Xcode, go to Runner target > General > Frameworks, Libraries, and Embedded Content"
echo "3. Click '+' and add BdkFFI.xcframework"
echo "4. Make sure it's set to 'Embed & Sign'"
echo ""
echo "Or run: ./scripts/configure_ios_project.sh to do this automatically"
