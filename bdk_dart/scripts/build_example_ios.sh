#!/usr/bin/env bash
set -euo pipefail

# Builds static lib for iOS (device + simulator) and copies universal lib into example/ios/Runner
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BDK_FFI_DIR="$ROOT_DIR/../bdk-ffi"
EXAMPLE_IOS_RUNNER="$ROOT_DIR/example/ios/Runner"

echo "Root: $ROOT_DIR"
echo "BDK ffi dir: $BDK_FFI_DIR"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "Detected Apple Silicon Mac - building for Apple Silicon simulator"
    SIMULATOR_TARGET="aarch64-apple-ios-sim"
else
    echo "Detected Intel Mac - building for Intel simulator"
    SIMULATOR_TARGET="x86_64-apple-ios"
fi

echo "Adding required rust targets..."
rustup target add "$SIMULATOR_TARGET" || true

cd "$BDK_FFI_DIR"

echo "Building release staticlib for $SIMULATOR_TARGET (simulator)..."
cargo build --release --target "$SIMULATOR_TARGET"

SIM_LIB="$BDK_FFI_DIR/target/$SIMULATOR_TARGET/release/libbdkffi.a"

if [[ ! -f "$SIM_LIB" ]]; then
  echo "Missing $SIM_LIB"
  exit 1
fi

UNIVERSAL_LIB="$ROOT_DIR/example/ios/Runner/libbdkffi.a"

mkdir -p "$(dirname "$UNIVERSAL_LIB")"

echo "Copying simulator library to $UNIVERSAL_LIB..."
cp "$SIM_LIB" "$UNIVERSAL_LIB"

echo "Universal library created at: $UNIVERSAL_LIB"

echo "NOTE: You still need to add libbdkffi.a to Xcode project (Runner) -> Build Phases -> Link Binary With Libraries"
echo "Also ensure Header Search Paths / Library Search Paths are configured if you add headers."

echo "Done."