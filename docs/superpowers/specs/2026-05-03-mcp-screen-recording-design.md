# MCP Screen Recording — Design

Date: 2026-05-03

## Overview

Add `start_recording` and `stop_recording` MCP tools plus a `recording://status` resource to `scrcpy_mcp`. Uses `adb shell screenrecord` (Android built-in). Recording requires an active mirroring session and falls back to the currently mirrored device when `device_id` is omitted.

## Approach: `RecordingAdb` interface inside `scrcpy_mcp`

Recording is a pure MCP concern. Rather than extending the `ScrcpyAdb` interface in `scrcpy_view` (which would pollute the mirroring abstraction layer), we define a narrow `RecordingAdb` interface inside `scrcpy_mcp`. `ScrcpyMcpAdb` implements both. `scrcpy_view` and `scrcpy_app` are not touched.

## File Changes

```
scrcpy_mcp/lib/src/
  recording_adb.dart           # new: RecordingAdb abstract interface
  recording_controller.dart    # new: state machine (idle ↔ recording)
  scrcpy_mcp_adapters.dart     # modified: ScrcpyMcpAdb implements RecordingAdb
  scrcpy_mcp_server.dart       # modified: registers tools/resource, holds RecordingController
scrcpy_mcp/test/
  recording_controller_test.dart  # new: unit tests with MockRecordingAdb
```

No changes to `scrcpy_view`, `scrcpy_app`, or `autoglm_adb`.

## Interfaces

### `RecordingAdb` (`recording_adb.dart`)

```dart
abstract class RecordingAdb {
  Future<Process> startScreenrecord(
    String deviceId,
    String remotePath, {
    int bitrate = 4000000,
    int maxTime = 180,
  });

  Future<void> pullFile(String deviceId, String remotePath, String localPath);

  Future<void> removeFile(String deviceId, String remotePath);
}
```

### `RecordingController` state machine (`recording_controller.dart`)

States: `idle` ↔ `recording`

Fields: `Process? _process`, `String? _deviceId`, `String? _remotePath`, `DateTime? _startTime`

Public API:
- `bool get isRecording`
- `RecordingStatus get status` — returns snapshot for the `recording://status` resource
- `Future<String> start(String deviceId, {int bitrate = 4000000, int maxTime = 180})` — returns `remotePath`
- `Future<String> stop({String? savePath})` — returns `localPath`

### `RecordingStatus` (plain data class)

```dart
class RecordingStatus {
  final bool isRecording;
  final String? deviceId;
  final DateTime? startTime;
  final String? remotePath;
}
```

## MCP Schema

### Tool: `start_recording`

Parameters:
- `device_id` (string, optional) — falls back to `_connectedDeviceId` from mirroring session; errors if neither is set
- `bitrate` (int, optional, default 4000000)
- `max_time` (int, optional, default 180)

Response on success:
```json
{ "status": "recording", "path_on_device": "/sdcard/mcp_rec_1714732800000.mp4" }
```

### Tool: `stop_recording`

Parameters:
- `save_path` (string, optional) — local file path; defaults to `~/Downloads/scrcpy_records/rec_<timestamp>.mp4`

Response on success:
```json
{ "status": "finished", "local_path": "/Users/hao/Downloads/scrcpy_records/rec_1714732800000.mp4", "size_bytes": 2621440 }
```

### Resource: `recording://status`

MIME type: `application/json`

```json
{
  "is_recording": true,
  "device_id": "emulator-5554",
  "start_time": "2026-05-03T10:00:00.000Z",
  "remote_path": "/sdcard/mcp_rec_1714732800000.mp4"
}
```

## Data Flow: `stop_recording`

```
MCP tool call
  → RecordingController.stop()
    → process.kill(ProcessSignal.sigint)   // graceful stop, preserves MP4 header
    → await process.exitCode               // wait for file flush
    → RecordingAdb.pullFile()              // adb pull to local
    → RecordingAdb.removeFile()            // adb shell rm temp file
    → return local_path
```

## File Naming

- Device: `/sdcard/mcp_rec_<epochMillis>.mp4`
- Local default: `~/Downloads/scrcpy_records/rec_<epochMillis>.mp4`

Timestamp-based names avoid collisions across multiple recordings.

## Error Handling

| Scenario | Behavior |
|----------|----------|
| `start_recording` with no active mirroring session | `isError: true` — "No active mirroring session. Call start_mirroring first." |
| `start_recording` while already recording | `isError: true` — includes current `device_id` and `start_time` |
| `stop_recording` with no active recording | Friendly message, `isError: false` |
| `screenrecord` process exits unexpectedly | `RecordingController` monitors `process.exitCode`, resets to idle; logs error |
| `adb pull` fails | `isError: true`; device file preserved (not deleted) |
| `save_path` directory missing | `Directory.create(recursive: true)` before pull |

## Testing Strategy

`MockRecordingAdb` implements `RecordingAdb`:
- `startScreenrecord` returns a fake `Process` backed by a `Completer<int>` for `exitCode`
- `pullFile` / `removeFile` record call arguments for assertion

Test cases (`recording_controller_test.dart`):
1. No mirroring session → `start_recording` returns error
2. Already recording → second `start_recording` returns error with current state
3. Full flow: start → stop → assert `pullFile` then `removeFile` called in order
4. Process exits unexpectedly → state resets to idle automatically
5. `adb pull` throws → `isError: true`, `removeFile` not called
6. `recording://status` returns correct JSON in both idle and recording states

## Constraints

- Android `screenrecord` max duration: 180 seconds (system limit, documented in tool description)
- Protected content (payment screens, etc.) may record as black — noted in `troubleshoot` prompt
- Recording only starts when `_session.isConnected` is true (requires active mirroring)
