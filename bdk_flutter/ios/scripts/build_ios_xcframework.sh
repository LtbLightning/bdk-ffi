#!/usr/bin/env bash
set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
IOS_DIR="$(cd "${THIS_DIR}/.." && pwd)"
# Resolve symlinks (CocoaPods installs plugin under .symlinks). Use real path.
if command -v python3 >/dev/null 2>&1; then
  REAL_IOS_DIR="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "${IOS_DIR}")"
else
  # Fallback: best-effort without resolving symlinks
  REAL_IOS_DIR="${IOS_DIR}"
fi
FRAMEWORKS_DIR="${REAL_IOS_DIR}/Frameworks"
XCFRAMEWORK_PATH="${FRAMEWORKS_DIR}/BdkFFI.xcframework"

# Try to locate the Rust crate directory robustly:
# 1) Assume monorepo layout: .../bdk-ffi/bdk_flutter/ios -> go two levels up to .../bdk-ffi
REPO_ROOT="$(cd "${REAL_IOS_DIR}/../.." && pwd)"
# Monorepo crate lives under <repo_root>/bdk-ffi
RUST_DIR="${REPO_ROOT}/bdk-ffi"
if [[ ! -f "${RUST_DIR}/Cargo.toml" ]]; then
  # 2) Walk up from REAL_IOS_DIR to find Cargo.toml containing bdk-ffi package
  CANDIDATE="${REAL_IOS_DIR}"
  while [[ "${CANDIDATE}" != "/" ]]; do
    if [[ -f "${CANDIDATE}/bdk-ffi/Cargo.toml" ]]; then
      RUST_DIR="${CANDIDATE}/bdk-ffi"
      break
    fi
    CANDIDATE="$(dirname "${CANDIDATE}")"
  done
fi
if [[ ! -f "${RUST_DIR}/Cargo.toml" ]]; then
  echo "Could not locate bdk-ffi Cargo.toml. Searched from ${REAL_IOS_DIR} upwards."
  exit 1
fi

mkdir -p "${FRAMEWORKS_DIR}"

echo "Building BDK XCFramework at: ${XCFRAMEWORK_PATH}"
echo "Using Rust sources at: ${RUST_DIR}"

cd "${RUST_DIR}"

# Ensure host toolchain compilers resolve correctly inside CocoaPods env
export CC=/usr/bin/cc
export CXX=/usr/bin/c++
export IPHONEOS_DEPLOYMENT_TARGET=13.0
export CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=/usr/bin/cc
export CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=/usr/bin/cc

rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim >/dev/null

echo "Building static libraries..."
cargo build --package bdk-ffi --profile release-smaller --target aarch64-apple-ios
cargo build --package bdk-ffi --profile release-smaller --target x86_64-apple-ios
cargo build --package bdk-ffi --profile release-smaller --target aarch64-apple-ios-sim

echo "Creating fat simulator library..."
mkdir -p target/lipo-ios-sim/release-smaller
lipo \
  target/aarch64-apple-ios-sim/release-smaller/libbdkffi.a \
  target/x86_64-apple-ios/release-smaller/libbdkffi.a \
  -create -output target/lipo-ios-sim/release-smaller/libbdkffi.a

echo "Creating XCFramework..."
rm -rf "${XCFRAMEWORK_PATH}"
xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release-smaller/libbdkffi.a \
  -library target/lipo-ios-sim/release-smaller/libbdkffi.a \
  -output "${XCFRAMEWORK_PATH}"

echo "BdkFFI.xcframework ready at ${XCFRAMEWORK_PATH}"

# Expose a stable lib path for -force_load from the app target.
# Use the active platform to select the correct archive from the XCFramework.
DEST_LIB_PATH="${REAL_IOS_DIR}/libbdkffi.a"
if [[ "${PLATFORM_NAME:-}" == "iphonesimulator" ]]; then
  SRC_LIB_PATH="${XCFRAMEWORK_PATH}/ios-arm64_x86_64-simulator/libbdkffi.a"
else
  SRC_LIB_PATH="${XCFRAMEWORK_PATH}/ios-arm64/libbdkffi.a"
fi
if [[ -f "${SRC_LIB_PATH}" ]]; then
  cp -f "${SRC_LIB_PATH}" "${DEST_LIB_PATH}"
  echo "Prepared lib for force_load at ${DEST_LIB_PATH}"
else
  echo "Expected library not found at ${SRC_LIB_PATH}"
  exit 1
fi


