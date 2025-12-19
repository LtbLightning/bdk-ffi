#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ANDROID_NDK_ROOT:-}" ]]; then
  echo "ANDROID_NDK_ROOT is not set"; exit 1
fi

OS="$(uname -s)"
case "${OS}" in
  Darwin*) NDK_BIN_DIR="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin" ;;
  Linux*)  NDK_BIN_DIR="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin" ;;
  *) echo "Unsupported OS: ${OS}"; exit 1 ;;
esac

export PATH="$NDK_BIN_DIR:$PATH"

LIB_NAME="libbdkffi.so"
TARGET_ARM64="aarch64-linux-android"
TARGET_X86_64="x86_64-linux-android"
TARGET_ARMEABI_V7A="armv7-linux-androideabi"

JNI_DIR="$(cd "$(dirname "$0")/../src/main/jniLibs" && pwd)"
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
RUST_DIR="${REPO_ROOT}/bdk-ffi"

mkdir -p "${JNI_DIR}/arm64-v8a" "${JNI_DIR}/x86_64" "${JNI_DIR}/armeabi-v7a"

cd "${RUST_DIR}"
rustup target add "${TARGET_ARM64}" "${TARGET_X86_64}" "${TARGET_ARMEABI_V7A}" >/dev/null

echo "Building Android shared libraries..."
CC="aarch64-linux-android24-clang" CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="aarch64-linux-android24-clang" cargo build --package bdk-ffi --profile release-smaller --target "${TARGET_ARM64}"
CC="x86_64-linux-android24-clang" CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="x86_64-linux-android24-clang" cargo build --package bdk-ffi --profile release-smaller --target "${TARGET_X86_64}"
CC="armv7a-linux-androideabi24-clang" CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="armv7a-linux-androideabi24-clang" cargo build --package bdk-ffi --profile release-smaller --target "${TARGET_ARMEABI_V7A}"

echo "Copying .so to plugin jniLibs..."
cp "target/${TARGET_ARM64}/release-smaller/${LIB_NAME}" "${JNI_DIR}/arm64-v8a/"
cp "target/${TARGET_X86_64}/release-smaller/${LIB_NAME}" "${JNI_DIR}/x86_64/"
cp "target/${TARGET_ARMEABI_V7A}/release-smaller/${LIB_NAME}" "${JNI_DIR}/armeabi-v7a/"

echo "Done."


