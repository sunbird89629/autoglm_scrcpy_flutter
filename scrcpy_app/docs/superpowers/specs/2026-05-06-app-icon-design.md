# Design Spec: ScrcpyApp AI-First App Icon

## 1. Overview
This document specifies the design and implementation of the application icon for `ScrcpyApp`. The app is a modern, AI-first desktop client for `scrcpy` (Android screen mirroring), and the icon needs to reflect its core capabilities: device connection, screen mirroring, and intelligent AI-driven control.

## 2. Design Vision: "Intelligent Lens" (方案 D)
The selected design concept is the **Intelligent Lens**. It moves beyond traditional mirroring metaphors to emphasize AI perception and automation.

### 2.1 Visual Elements
- **Background**: A deep gradient using Indigo shades (`#3F51B5` to `#1A237E`). This aligns with the app's existing theme and creates a premium, high-tech feel.
- **Device Frame**: A minimalist, rounded-rectangle stroke representing the Android phone screen.
- **The Lens**: A central, bright focal point (white dot) representing the AI's "eye" or processing core.
- **Scanning Line**: A horizontal cyan (`#00BCD4`) line with a subtle glow effect, symbolizing real-time AI perception and content understanding.

### 2.2 Aesthetic Principles
- **Minimalist/Modern**: Clean lines and high contrast.
- **AI-First**: Emphasizes sensing and intelligence over physical hardware.
- **Consistency**: The color palette and style match the existing UI and `tray_icon.png`.

## 3. Implementation Strategy
We will use automated tools to ensure the icon looks great across all platforms.

### 3.1 Tools
- **`flutter_launcher_icons`**: The standard package for generating platform-specific icon sets (macOS, Android, iOS, Windows, Web).

### 3.2 Assets to Generate
- **Main App Icon**:
    - macOS: `.icns` file with standard sizes (16x16 up to 1024x1024).
    - Android: Adaptive icons with background and foreground layers.
    - iOS: Standard high-resolution icons.
- **Tray Icon**: A simplified, monochrome version for the system tray (macOS/Windows).

### 3.3 Workflow
1. Add `flutter_launcher_icons` to `dev_dependencies`.
2. Create a high-resolution source icon (PNG/SVG).
3. Configure `flutter_launcher_icons` in `pubspec.yaml` or a separate `flutter_launcher_icons.yaml`.
4. Run `dart run flutter_launcher_icons` to generate all assets.
5. Verify icons in the application build.

## 4. Success Criteria
- The icon is clearly visible and recognizable in the macOS Dock and Application folder.
- The design reflects the AI-first nature of the tool.
- The build process remains clean and reproducible.
