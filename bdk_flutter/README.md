# bdk_flutter

Flutter wrapper over `bdk_dart` that builds and bundles native BDK binaries for iOS and Android at build time.

## Structure
- Depends on `bdk_dart` for Dart FFI API.
- iOS: CocoaPods runs a script phase to build `BdkFFI.xcframework` from the Rust crate and vendors it.
- Android: Gradle preBuild task builds `.so` for all ABIs and packages them in `jniLibs/`.

## Usage
Add to your Flutter app:

```yaml
dependencies:
  bdk_flutter:
    path: ../bdk-ffi/bdk_flutter
```

Then import:

```dart
import 'package:bdk_flutter/bdk_flutter.dart';
```

## iOS requirements
- Xcode and Rust targets: `aarch64-apple-ios`, `x86_64-apple-ios`, `aarch64-apple-ios-sim`

## Android requirements
- ANDROID_NDK_ROOT set and NDK r27+ installed


