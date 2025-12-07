#!/usr/bin/env bash
set -euo pipefail

# Parse command line arguments
TARGET=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --target)
            TARGET="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--target ios|android|macos|linux|windows]"
            exit 1
            ;;
    esac
done

OS=$(uname -s)
echo "Running on $OS"

if [[ -n "$TARGET" ]]; then
    echo "Target platform: $TARGET"
fi

dart --version
dart pub get

# Determine library name based on OS
if [[ "$OS" == "Darwin" ]]; then
    LIBNAME=libbdkffi.dylib
elif [[ "$OS" == "Linux" ]]; then
    LIBNAME=libbdkffi.so
else
    echo "Unsupported os: $OS"
    exit 1
fi

cd ../bdk-ffi
echo "Generating bdk dart bindings..."
cargo build --profile dev
pwd
ls ./
cargo run --profile dev --bin uniffi-bindgen -- --library ./target/debug/$LIBNAME --language dart --out-dir ../bdk_dart/lib/

# Build for specific target if specified
if [[ -n "$TARGET" ]]; then
    case $TARGET in
        ios)
            echo "Building for iOS (aarch64-apple-ios and x86_64-apple-ios simulator)..."
            rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
            cargo build --profile dev --target aarch64-apple-ios
            cargo build --profile dev --target x86_64-apple-ios
            cargo build --profile dev --target aarch64-apple-ios-sim
            echo "iOS libraries built in:"
            echo "  - target/aarch64-apple-ios/debug/$LIBNAME"
            echo "  - target/x86_64-apple-ios/debug/$LIBNAME"
            echo "  - target/aarch64-apple-ios-sim/debug/$LIBNAME"
            ;;
        android)
            echo "Building for Android (armv7, aarch64, i686, x86_64)..."
            rustup target add armv7-linux-androideabi aarch64-linux-android i686-linux-android x86_64-linux-android
            cargo build --profile dev --target armv7-linux-androideabi
            cargo build --profile dev --target aarch64-linux-android
            cargo build --profile dev --target i686-linux-android
            cargo build --profile dev --target x86_64-linux-android
            echo "Android libraries built in:"
            echo "  - target/armv7-linux-androideabi/debug/$LIBNAME"
            echo "  - target/aarch64-linux-android/debug/$LIBNAME"
            echo "  - target/i686-linux-android/debug/$LIBNAME"
            echo "  - target/x86_64-linux-android/debug/$LIBNAME"
            ;;
        macos)
            echo "Building for macOS (aarch64 and x86_64)..."
            rustup target add aarch64-apple-darwin x86_64-apple-darwin
            cargo build --profile dev --target aarch64-apple-darwin
            cargo build --profile dev --target x86_64-apple-darwin
            
            echo "Building macOS universal library..."
            lipo -create -output ../bdk_dart/$LIBNAME \
                ./target/aarch64-apple-darwin/debug/$LIBNAME \
                ./target/x86_64-apple-darwin/debug/$LIBNAME
            echo "Universal macOS library created at: ../bdk_dart/$LIBNAME"
            ;;
        linux)
            echo "Building for Linux (x86_64)..."
            rustup target add x86_64-unknown-linux-gnu
            cargo build --profile dev --target x86_64-unknown-linux-gnu
            
            echo "Copying Linux library..."
            LINUX_LIBNAME=libbdkffi.so
            cp ./target/x86_64-unknown-linux-gnu/debug/$LINUX_LIBNAME ../bdk_dart/$LINUX_LIBNAME
            echo "Linux library created at: ../bdk_dart/$LINUX_LIBNAME"
            ;;
        windows)
            echo "Building for Windows (x86_64)..."
            rustup target add x86_64-pc-windows-gnu x86_64-pc-windows-msvc
            cargo build --profile dev --target x86_64-pc-windows-msvc
            
            echo "Windows library built in:"
            echo "  - target/x86_64-pc-windows-msvc/debug/bdkffi.dll"
            ;;
        *)
            echo "Unknown target: $TARGET"
            echo "Valid targets: ios, android, macos, linux, windows"
            exit 1
            ;;
    esac
else
    # Default behavior - build for current OS
    if [[ "$OS" == "Darwin" ]]; then
        echo "Generating native binaries for macOS..."
        rustup target add aarch64-apple-darwin
        cargo build --profile dev --target aarch64-apple-darwin

        echo "Building macOS library..."
        lipo -create -output ../bdk_dart/$LIBNAME \
            ./target/aarch64-apple-darwin/debug/$LIBNAME
        echo "macOS library created at: ../bdk_dart/$LIBNAME"
    else
        echo "Linux build - skipping native binary generation (use --target linux to build)"
    fi
fi

echo "All done!"
