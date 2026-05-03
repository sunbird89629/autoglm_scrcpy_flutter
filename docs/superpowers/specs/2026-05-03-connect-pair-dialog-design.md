# Connect / Pair Dialog Design

**Date:** 2026-05-03
**Status:** Approved
**Scope:** `autoglm_app/lib/pages/devices_page.dart` + i18n files + tests

## Overview

Replace the current minimal `_showPairDialog` (IP + port + code, no loading state, no validation, raw exception text) with a polished `_ConnectPairDialog` StatefulWidget that handles both reconnection and first-time pairing in a single progressive flow.

## Decisions

| Question | Decision |
|---|---|
| Connect vs. Pair entry point | Single dialog — try `connect()` first; reveal pair code field only on failure |
| Error display | Snackbar (bottom of screen); dialog stays open |
| Input validation timing | On submit only; no real-time field highlighting |
| Dialog state management | Local `StatefulWidget` (not Riverpod) |
| IP + port in Step 2 | Locked (read-only) — user already entered them in Step 1 |
| After pair success | Auto-call `connect()`, then close dialog + Snackbar + refresh |

## Flow

```
Open dialog
  └─ Step 1: IP + Port → [Connect]
       ├─ success  → close dialog · Snackbar "Connected to {serial}" · invalidate provider
       └─ failure  → Step 2: IP + Port (locked) + Code field → [Pair]
            ├─ success  → connect() → close dialog · Snackbar "Paired and connected to {serial}" · invalidate provider
            └─ failure  → Snackbar with mapped error · dialog stays open · [← Back] returns to Step 1
```

Loading state (both steps): action button replaced with `CircularProgressIndicator`; all fields `enabled: false`.

## `_ConnectPairDialog` Widget

**File:** `autoglm_app/lib/pages/devices_page.dart` (private widget, same file)

```dart
enum _DialogStep { connect, pair }

class _ConnectPairDialog extends StatefulWidget { ... }

class _ConnectPairDialogState extends State<_ConnectPairDialog> {
  _DialogStep _step = _DialogStep.connect;
  bool _isLoading = false;

  final _ipCtrl   = TextEditingController();
  final _portCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _ipCtrl.dispose(); _portCtrl.dispose(); _codeCtrl.dispose();
    super.dispose();
  }
  ...
}
```

The existing `_showPairDialog` method on `DevicesPage` is replaced by a call to `showDialog` that instantiates `_ConnectPairDialog`. The Toolbar `add_link` button wires to this new dialog.

## Validation (on submit)

| Field | Rule | Error key |
|---|---|---|
| IP | non-empty; digits and dots only; at least two dots | `invalid_ip` |
| Port | non-empty; integer 1–65535 | `invalid_port` |
| Code (Step 2) | exactly 6 digits | `invalid_code` |

Validation failures are shown as Snackbar (same as operation errors — consistent UX).

## Error Mapping

**Step 1 — `connect()` failure:** `AdbClient.connect()` throws `AdbException("Connect failed: $output")`. Display the raw `AdbException.message` in the Snackbar and advance to Step 2 (pair code field). Exception: if message contains `"already connected"`, treat as success (close dialog, refresh).

**Step 2 — `pair()` failure:** Map `AdbException.message` substrings → Snackbar i18n key:

| Substring | Key |
|---|---|
| `"refused"` | `connection_refused` |
| `"Invalid pairing code"` | `invalid_pairing_code` |
| `"Pairing code must be 6 digits"` | `invalid_code` |
| anything else | display raw message |

## i18n Keys

New keys added under `devices_page` in both `en-US.i18n.json` and `zh-CN.i18n.json`:

| Key | English | Chinese |
|---|---|---|
| `connect_device` | Connect Device | 连接设备 |
| `connect` | Connect | 连接 |
| `connecting` | Connecting... | 连接中… |
| `not_paired_hint` | Device not paired. Enter the pairing code from Wireless Debugging. | 设备未配对，请从手机「无线调试」获取配对码 |
| `pair` | Pair | 配对 |
| `pairing` | Pairing... | 配对中… |
| `back` | Back | 返回 |
| `connected_to` | Connected to {serial} | 已连接到 {serial} |
| `paired_and_connected` | Paired and connected to {serial} | 已配对并连接到 {serial} |
| `invalid_ip` | Invalid IP address | IP 地址格式无效 |
| `invalid_port` | Port must be between 1 and 65535 | 端口必须在 1–65535 之间 |
| `invalid_code` | Pairing code must be 6 digits | 配对码必须是 6 位数字 |
| `connection_refused` | Connection refused. Make sure Wireless Debugging is enabled on the device. | 连接被拒绝，请确认手机上已开启无线调试 |
| `invalid_pairing_code` | Invalid pairing code. Get a new one from Wireless Debugging. | 配对码无效，请在手机上重新获取 |
| `already_connected` | Device already connected. | 设备已连接 |

## File Map

| File | Action |
|---|---|
| `autoglm_app/lib/pages/devices_page.dart` | Extract `_ConnectPairDialog` + `_DialogStep`; remove `_showPairDialog` method |
| `autoglm_app/lib/i18n/en-US.i18n.json` | Add 15 keys above |
| `autoglm_app/lib/i18n/zh-CN.i18n.json` | Add 15 keys above (Chinese) |
| `autoglm_app/lib/i18n/strings.g.dart` (generated) | Regenerated via `melos run gen:i18n` |
| `autoglm_app/test/devices_page_test.dart` | Add dialog tests (see below) |

## Testing

**New tests in `autoglm_app/test/devices_page_test.dart`** — mock `adbClientProvider` with a fake `AdbClient`:

| Test | Assertion |
|---|---|
| Dialog opens with IP + port fields; no code field visible | `find.byKey(Key('code_field'))` → `findsNothing` |
| Connect success: dialog closes, success Snackbar appears | `find.text('Connected to ...')` |
| Connect failure: code field becomes visible | `find.byKey(Key('code_field'))` → `findsOneWidget` |
| IP validation: empty IP shows invalid_ip Snackbar | `find.text(t.devices_page.invalid_ip)` |
| Port validation: port=0 shows invalid_port Snackbar | `find.text(t.devices_page.invalid_port)` |
| Code validation: 5-digit code shows invalid_code Snackbar | `find.text(t.devices_page.invalid_code)` |
| Pair success: Snackbar shows "Paired and connected to ..." | `find.text('Paired and connected to ...')` |
| Pair failure: Snackbar shows mapped error; dialog stays open | `find.byType(_ConnectPairDialog)` → `findsOneWidget` |

Tests use `ProviderScope` overrides for `adbClientProvider` and `adbDevicesWithInfoProvider`; no real ADB process.

## Out of Scope

- Auto-refresh on device connect/disconnect (separate TODO item)
- ADB binary missing / platform-tools download error handling (Phase 2 item B)
- Saving known devices for one-tap reconnect
