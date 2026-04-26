# Project Overview: autoglm_scrcpy

`autoglm_scrcpy` is a Flutter/Dart implementation of the [Scrcpy](https://github.com/Genymobile/scrcpy) protocol, tailored for the AutoGLM ecosystem. It enables high-performance, low-latency screen streaming from Android devices to a host application.

## Key Technologies
- **Flutter & Dart**: Core development framework.
- **ADB (Android Debug Bridge)**: Device management, file pushing, and port forwarding (via `autoglm_adb`).
- **Scrcpy Server (v3.3.4)**: The official scrcpy JAR binary used for on-device capture and encoding.
- **H.264 (Annex-B)**: The primary video stream format.
- **WebCodecs API**: Leveraged in the built-in web player for hardware-accelerated decoding.
- **WebSocket & HTTP**: Protocols used to distribute the video stream to local or remote clients.

## Architecture
The project is structured as a library with several internal components:

- **`ScrcpyServer`**: The main entry point that manages the entire lifecycle of a scrcpy session, including ADB setup and socket management.
- **`ScrcpyStreamParser`**: A robust binary parser that decodes the scrcpy protocol header, metadata, and video packets (with PTS handling).
- **`ScrcpyWebsocketServer`**: A modern proxy that forwards H.264 packets over WebSocket. It performs **SPS/PPS injection** into every keyframe to allow late-joining clients (like WebViews) to start decoding immediately without waiting for the next global header.
- **`ScrcpyProxyServer`**: A legacy proxy that remuxes raw H.264 into **MPEG-TS** over HTTP, primarily for compatibility with players that don't support raw H.264 demuxing (e.g., certain builds of `media_kit`).
- **`MpegTsMuxer`**: A custom implementation for encapsulating H.264 into MPEG Transport Stream.

## Building and Running

### Prerequisites
- Flutter SDK installed.
- Android device with USB debugging enabled.
- ADB accessible in your system PATH.

### Commands
- **Install dependencies**:
  ```bash
  flutter pub get
  ```
- **Run the example application** (includes a dedicated WebView test screen):
  ```bash
  cd example
  flutter run -d macos # or linux/windows
  ```
- **Run specific tests**:
  ```bash
  flutter test test/scrcpy_stream_parser_test.dart
  ```
- **Manual verification script**:
  ```bash
  # Runs a standalone app that starts scrcpy and provides a URL for VLC testing
  flutter run test/manual_scrcpy_test.dart -d macos
  ```

## Development Conventions

- **Logging**: Always use `appLogger` from `package:autoglm_core` for consistent diagnostic output across the suite.
- **Testing**:
  - **Unit Tests**: Use `MockAdbClient` to test logic without requiring a physical device.
  - **Integration Tests**: Targeted at real device behavior; expect these to fail if no device is connected.
- **Assets**: 
  - The scrcpy JAR is stored in `assets/scrcpy-server-v3.3.4`.
  - The web player is in `assets/web_player/`.
  - Both are extracted to temporary directories at runtime by `ScrcpyServer`.
- **Low Latency**: Priority is given to minimizing buffer depth. Avoid B-frames and use `latency=1` in encoder options.

## Auto Debug For Me

When i ask you auto debug for me,you should test like this

- stop the app if it is running.
- use launch app to start app.
- connect running app with **Dart Tooling Daemon** .