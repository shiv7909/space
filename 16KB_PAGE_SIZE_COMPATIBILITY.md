# 16 KB Page Size Compatibility Guide

This document outlines the steps taken to ensure the Habitz app is compatible with 16 KB page sizes, as required for Google Play Store submissions starting from certain Android versions.

## Background
Starting with Android 15, some devices use 16 KB page sizes instead of the traditional 4 KB. Apps must be compatible to run on these devices and to meet Play Store requirements.

## Requirements
- Flutter SDK: 3.10 or later (current: ^3.7.0-323.0.dev)
- Android Gradle Plugin: 8.1.0 or later (current: 8.9.1)
- Target SDK: 34 or higher
- ABI Filters: arm64-v8a (for 16 KB page size devices)

## Changes Made
1. **android/app/build.gradle.kts**:
   - Added `ndk { abiFilters.addAll(listOf("arm64-v8a")) }` to limit to ARM64 architecture.
   - **Note**: Explicit page size settings are not required. This project uses Android Gradle Plugin (AGP) 8.9.1, which automatically aligns uncompressed native libraries to 16 KB (a feature introduced in AGP 8.3).

## Verification
- Build the app and ensure it compiles without errors.
- Test on devices with 16 KB page size support (if available).
- The app should now be compatible with 16 KB page sizes.

## Additional Notes
- Ensure all native dependencies and plugins support 16 KB page sizes.
- If using custom native code, verify alignment and compatibility.
- For more details, refer to the official Android and Flutter documentation on 16 KB page size support.
