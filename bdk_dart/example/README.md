BDK Dart Example
=================

This example app demonstrates how to use the `bdk_dart` UniFFI-generated Dart bindings in a Flutter app, and how to bundle the native BDK library for iOS.

Quick start (iOS)
------------------

1. Build the static library for iOS (device + simulator) and copy to the example Runner

   From the root of the repository run:

   ```bash
   cd bdk_dart/scripts
   ./build_example_ios.sh
   ```

   This script builds `libbdkffi.a` for device and simulator and uses `lipo` to produce a universal `libbdkffi.a` at `example/ios/Runner/libbdkffi.a`.

2. Open the Xcode workspace for the example app

   ```bash
   open example/ios/Runner.xcworkspace
   ```

3. Add the static library to the Xcode project

   - Drag `libbdkffi.a` into the Runner project (preferably into a `Frameworks/` group).
   - In the project target, go to Build Phases -> Link Binary With Libraries and ensure `libbdkffi.a` is listed.

4. Build & Run on device/simulator

   - After linking the static library, build and run the app as usual from Xcode or `flutter run`.

Running Integration Tests on iOS Simulator
-------------------------------------------

To run the BDK tests on an iOS simulator (which uses the native library):

1. **Build the static library** (if not already done):
   ```bash
   cd bdk_dart/scripts
   ./build_example_ios.sh
   ```

2. **Link the library in Xcode** (see step 3 above)

3. **Get dependencies**:
   ```bash
   cd bdk_dart/example
   flutter pub get
   ```

4. **List available iOS simulators**:
   ```bash
   flutter devices
   ```

5. **Run integration tests on a simulator**:
   ```bash
   flutter test integration_test/bdk_test.dart -d <simulator-id>
   ```

   For example:
   ```bash
   flutter test integration_test/bdk_test.dart -d "iPhone 15 Pro"
   ```

   Or use the device ID:
   ```bash
   flutter test integration_test/bdk_test.dart -d A1B2C3D4-1234-5678-90AB-CDEFG1234567
   ```

The integration tests will:
- Launch the Flutter app on the iOS simulator
- Execute the BDK library tests using the native Rust library
- Print detailed output showing each test step
- Verify all BDK functionality works correctly on iOS

Notes
-----

- The example app references the `bdk_dart` package via a path dependency. Run `flutter pub get` inside `example/` before running.
- For automated packaging (CocoaPods or plugin), you may prefer to build an XCFramework and add it as a vendored framework inside a `.podspec` for a plugin. This repo contains scripts to help build the static library; packaging into an XCFramework is left as an exercise.

Troubleshooting
---------------

- If the `build_example_ios.sh` script fails due to missing rust targets, install them with `rustup target add aarch64-apple-ios x86_64-apple-ios`.
- If you run into permission issues while building under `target/`, check your file permissions or try running with appropriate user privileges.
- If integration tests fail with library loading errors, ensure the static library is properly linked in the Xcode project (step 3 above).
- For "DynamicLibrary.executable()" errors, make sure you've added `libbdkffi.a` to Build Phases -> Link Binary With Libraries in Xcode.

