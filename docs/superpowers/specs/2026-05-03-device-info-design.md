# Device Info Display Design

**Date:** 2026-05-03  
**Status:** Approved  
**Scope:** `packages/autoglm_adb` + `autoglm_app`

## Overview

Replace raw ADB serial IDs in `DevicesPage` with rich device cards showing model name, manufacturer, Android version, connection type (USB / Wi-Fi), and connection status (online / offline / unauthorized).

## Decisions

| Question | Decision |
|---|---|
| Data source | Single `adb shell getprop` call per device, parsed client-side |
| API shape | New `getDevicesWithInfo()` on `AdbClient`; existing `getDevices()` unchanged |
| Status source | Parsed from `adb devices` output (same call, extended parser) |
| Connection type | Inferred from serial: contains `:` → Wi-Fi, otherwise USB |
| Failure handling | `offline`/`unauthorized` devices skip `getprop`; parse errors degrade gracefully to `null` fields |

## Data Model

**New file:** `packages/autoglm_adb/lib/src/device_info.dart`

```dart
enum DeviceStatus { online, offline, unauthorized }

class DeviceInfo {
  const DeviceInfo({
    required this.serial,
    required this.status,
    required this.isWifi,
    this.model,
    this.manufacturer,
    this.androidVersion,
    this.sdkVersion,
  });

  final String serial;
  final DeviceStatus status;
  final bool isWifi;            // serial.contains(':')
  final String? model;          // ro.product.model
  final String? manufacturer;   // ro.product.manufacturer
  final String? androidVersion; // ro.build.version.release
  final int? sdkVersion;        // ro.build.version.sdk
}
```

All `String?` / `int?` fields are null when the device is not online or when `getprop` output cannot be parsed.

## `AdbClient` Extension

**New method** added to `packages/autoglm_adb/lib/src/adb_client.dart`:

```dart
Future<List<DeviceInfo>> getDevicesWithInfo() async
```

**Implementation steps:**

1. Run `adb devices` — parse each non-header line into `(serial, rawStatus)`.
2. Map `rawStatus` string → `DeviceStatus`:
   - `"device"` → `DeviceStatus.online`
   - `"offline"` → `DeviceStatus.offline`
   - anything else (e.g. `"unauthorized"`) → `DeviceStatus.unauthorized`
3. For each `online` device, launch `adb -s <serial> shell getprop` concurrently via `Future.wait`.
4. Parse `getprop` output with regex `\[(.+?)\]: \[(.+?)\]` into a `Map<String, String>`.
5. Extract:
   - `ro.product.model` → `model`
   - `ro.product.manufacturer` → `manufacturer`
   - `ro.build.version.release` → `androidVersion`
   - `ro.build.version.sdk` → `sdkVersion` (parsed as `int`, null on failure)
6. `offline` / `unauthorized` devices: skip `getprop`, all info fields are null.
7. Any exception during `getprop` is caught; device is still returned with null info fields.

**Existing `getDevices()` is not modified.**

## Riverpod Provider

**Modified file:** `autoglm_app/lib/providers/adb_provider.dart`

```dart
final adbDevicesWithInfoProvider =
    FutureProvider.autoDispose<List<DeviceInfo>>((ref) async {
  final client = await ref.watch(adbClientProvider.future);
  return client.getDevicesWithInfo();
});
```

The existing `adbDevicesProvider` is kept — `scrcpy_provider` and other consumers continue to use it.

## DevicesPage UI

**Modified file:** `autoglm_app/lib/pages/devices_page.dart`

Switches from `adbDevicesProvider` to `adbDevicesWithInfoProvider`. Each device card displays:

```
┌──────────────────────────────────────────────────────┐
│  [avatar]  Xiaomi 14 Pro                  ● online  │
│            Xiaomi  ·  Android 14 (API 34)           │
│            serial: 192.168.1.5:5555   📶 Wi-Fi      │
└──────────────────────────────────────────────────────┘
```

**Card sections:**

- **Title:** `model` if available, otherwise `serial`
- **Subtitle line 1:** `manufacturer · Android androidVersion (API sdkVersion)` — omitted entirely when all fields are null
- **Subtitle line 2:** `serial: <serial>  <connection-type-icon>`
- **Trailing badge:**

| Status | Color | Icon |
|---|---|---|
| `online` | `colorScheme.primary` | `Icons.circle` (filled, small) |
| `offline` | `colorScheme.outline` | `Icons.circle_outlined` |
| `unauthorized` | `colorScheme.error` | `Icons.warning_amber` |

Connection type icons: `Icons.wifi` for Wi-Fi, `Icons.usb` for USB.

Selection behavior (highlight + check mark) is unchanged.

## File Map

| File | Action |
|---|---|
| `packages/autoglm_adb/lib/src/device_info.dart` | Create — `DeviceInfo` + `DeviceStatus` |
| `packages/autoglm_adb/lib/src/adb_client.dart` | Add `getDevicesWithInfo()` |
| `packages/autoglm_adb/lib/autoglm_adb.dart` | Export `DeviceInfo` |
| `autoglm_app/lib/providers/adb_provider.dart` | Add `adbDevicesWithInfoProvider` |
| `autoglm_app/lib/pages/devices_page.dart` | Switch provider + rewrite card widget |

## Testing

| Test file | Coverage |
|---|---|
| `packages/autoglm_adb/test/device_info_test.dart` | `getprop` output parsing; `adb devices` status parsing; offline/unauthorized skip; parse error degradation |
| `autoglm_app/test/devices_page_test.dart` | Card renders for all three `DeviceStatus` values; null-info degradation (shows serial as title, `—` subtitle); connection type icons |

Tests use mocked `AdbProcessRunner` — no real device required.

## Out of Scope

- Auto-refresh on device connect/disconnect (manual refresh button retained)
- Device nickname / custom label
- `selectedDeviceIdProvider` type change (still `String?` serial)
