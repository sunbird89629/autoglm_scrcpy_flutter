# App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate high-quality app icons and tray icons for ScrcpyApp using the "Intelligent Lens" design.

**Architecture:** Use a Python script with Pillow to generate a high-resolution source image, then use `flutter_launcher_icons` to generate platform-specific assets.

**Tech Stack:** Flutter, Dart, Python (Pillow), `flutter_launcher_icons`.

---

### Task 1: Add Dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `flutter_launcher_icons` to `dev_dependencies`**

Run: `dart pub add dev:flutter_launcher_icons`

- [ ] **Step 2: Verify `pubspec.yaml` update**

Run: `grep "flutter_launcher_icons" pubspec.yaml`
Expected: `flutter_launcher_icons: ^0.13.1` (or latest)

### Task 2: Generate Source Assets

**Files:**
- Create: `scripts/generate_icon.py`
- Create: `assets/app_icon_source.png`
- Modify: `assets/tray_icon.png`

- [ ] **Step 1: Create the icon generation script**

```python
from PIL import Image, ImageDraw

def create_app_icon():
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Gradient (Indigo)
    # Drawing a simplified gradient using circles/rects or just a solid color for the plan
    # Let's use a solid deep indigo for the base
    draw.rounded_rectangle([0, 0, size, size], radius=size*0.2, fill=(26, 35, 126, 255))
    
    # 2. Device Frame (Rounded Rect)
    frame_padding = size * 0.15
    draw.rounded_rectangle(
        [frame_padding, frame_padding, size - frame_padding, size - frame_padding],
        radius=size*0.05,
        outline=(255, 255, 255, 80),
        width=int(size * 0.02)
    )

    # 3. Scanning Line (Cyan)
    line_y = size // 2
    draw.line([0, line_y, size, line_y], fill=(0, 188, 212, 255), width=int(size * 0.01))

    # 4. The Lens (White Dot)
    dot_radius = size * 0.03
    draw.ellipse(
        [size//2 - dot_radius, size//2 - dot_radius, size//2 + dot_radius, size//2 + dot_radius],
        fill=(255, 255, 255, 255)
    )

    img.save('assets/app_icon_source.png')
    print("App icon source generated.")

def create_tray_icon():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Simplified monochrome version
    draw.rounded_rectangle([4, 4, size-4, size-4], radius=8, outline=(255, 255, 255, 255), width=4)
    draw.line([0, size//2, size, size//2], fill=(255, 255, 255, 255), width=2)
    draw.ellipse([size//2-3, size//2-3, size//2+3, size//2+3], fill=(255, 255, 255, 255))
    
    img.save('assets/tray_icon.png')
    print("Tray icon generated.")

if __name__ == "__main__":
    create_app_icon()
    create_tray_icon()
```

- [ ] **Step 2: Run the script to generate assets**

Run: `python3 scripts/generate_icon.py`
Expected: `assets/app_icon_source.png` and `assets/tray_icon.png` created.

- [ ] **Step 3: Commit source assets**

```bash
git add assets/app_icon_source.png assets/tray_icon.png scripts/generate_icon.py
git commit -m "assets: generate AI-first app icon source and tray icon"
```

### Task 3: Configure and Generate Icons

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add `flutter_launcher_icons` configuration to `pubspec.yaml`**

Append to `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/app_icon_source.png"
  macos:
    generate: true
    image_path: "assets/app_icon_source.png"
```

- [ ] **Step 2: Run the generator**

Run: `flutter pub run flutter_launcher_icons`

- [ ] **Step 3: Verify macOS icons**

Run: `ls macos/Runner/Assets.xcassets/AppIcon.appiconset/`
Expected: Multiple PNG files and `Contents.json`.

- [ ] **Step 4: Commit generated assets**

```bash
git add pubspec.yaml macos/Runner/Assets.xcassets/AppIcon.appiconset/
git commit -m "feat: generate platform-specific app icons"
```

### Task 4: Cleanup

**Files:**
- Remove: `scripts/generate_icon.py`
- Remove: `assets/app_icon_source.png` (optional, but keep if needed for future updates)

- [ ] **Step 1: Remove temporary scripts**

Run: `rm scripts/generate_icon.py`

- [ ] **Step 2: Commit cleanup**

```bash
git add scripts/generate_icon.py
git commit -m "chore: cleanup icon generation script"
```
