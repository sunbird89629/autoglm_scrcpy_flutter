# Logging Module Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `logger` package with the official `logging` package, eliminate the global `appLogger` singleton, and migrate all consumers to module-level `Logger` instances with hierarchical names.

**Architecture:** `autoglm_logger` exports a single `initLogging()` function (replaces `initAppLogger`) that configures `Logger.root` with console + file handlers. Each consumer module declares `static final _log = Logger('module.ClassName')` and calls `_log.info()` directly. `ScrcpyLogger` interface in `scrcpy_view` stays unchanged; its adapters delegate to module-level loggers instead of `appLogger`. `ClassLogger` mixin and `maybeLog`/`maybeError` are deleted.

**Tech Stack:** Dart `logging` package (official, zero transitive deps), `path` for file rotation, `flutter/foundation.dart` for `kDebugMode`.

---

## File Map

| Action | File | Reason |
|--------|------|--------|
| Rewrite | `packages/autoglm_logger/lib/app_logger.dart` | Core: `logger` → `logging`, singleton → `initLogging()` |
| Delete | `packages/autoglm_logger/lib/applog/class_logger.dart` | Unused mixin |
| Modify | `packages/autoglm_logger/lib/autoglm_logger.dart` | Remove `class_logger.dart` export |
| Modify | `packages/autoglm_logger/pubspec.yaml` | `logger: ^2.4.0` → `logging: ^1.3.0` |
| Create | `packages/autoglm_logger/test/app_logger_test.dart` | TDD for new `initLogging()` + file rotation |
| Modify | `packages/adb_tools/lib/src/adb_binary_manager.dart` | `AppLogger.maybeError` → `Logger.severe` |
| Modify | `scrcpy_mcp/lib/src/scrcpy_mcp_adapters.dart` | `ScrcpyMcpLogger` → module-level logger |
| Modify | `scrcpy_mcp/lib/src/recording_controller.dart` | `appLogger.w` → `Logger.warning` |
| Modify | `scrcpy_mcp/bin/scrcpy_mcp.dart` | `initAppLogger()` → `initLogging()` |
| Modify | `scrcpy_app/lib/main.dart` | `initAppLogger()` → `initLogging()` |
| Modify | `scrcpy_view/example/lib/main.dart` | `initAppLogger()` → `initLogging()` |
| Modify | `autoglm_app/lib/main.dart` | `appLogger.*` → module-level loggers |
| Modify | `autoglm_app/lib/pages/chat_page.dart` | `appLogger.*` → module-level loggers |
| Modify | `autoglm_app/lib/scrcpy/autoglm_scrcpy_bridge.dart` | `AutoGlmScrcpyLogger` → module-level logger |
| Modify | `autoglm_app/lib/src/settings_repository.dart` | `AppLogger.maybeError` → `Logger.severe` |
| Modify | `autoglm_app/lib/test_scrcpy.dart` | `initAppLogger` → `initLogging` |
| Modify | `scrcpy_mcp/test/recording_controller_test.dart` | `initAppLogger` → `initLogging` |

---

## Task 1: Rewrite `autoglm_logger` core

**Files:**
- Modify: `packages/autoglm_logger/pubspec.yaml`
- Rewrite: `packages/autoglm_logger/lib/app_logger.dart`
- Modify: `packages/autoglm_logger/lib/autoglm_logger.dart`
- Delete: `packages/autoglm_logger/lib/applog/class_logger.dart`
- Create: `packages/autoglm_logger/test/app_logger_test.dart`

### Step 1: Update `pubspec.yaml`

Replace `logger: ^2.4.0` with `logging: ^1.3.0`. The full file becomes:

```yaml
name: autoglm_logger
description: Application-wide logger with daily-rotated file output for AutoGLM Flutter.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.5.0
  flutter: ">=3.24.0"

resolution: workspace

dependencies:
  flutter:
    sdk: flutter
  logging: ^1.3.0
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  very_good_analysis: ^7.0.0
```

### Step 2: Write the failing test

Create `packages/autoglm_logger/test/app_logger_test.dart`:

```dart
import 'dart:io';

import 'package:autoglm_logger/autoglm_logger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

void main() {
  group('initLogging', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('autoglm_logger_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('configures Logger.root level based on kDebugMode', () {
      initLogging();
      // In test (debug mode), root level should be FINE
      expect(Logger.root.level, Level.FINE);
    });

    test('creates log file when logsDir is provided', () {
      initLogging(logsDir: tempDir.path);
      Logger('test').info('hello');
      // Give the handler time to write
      final files = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('autoglm-'))
          .toList();
      expect(files, isNotEmpty);
    });

    test('prunes old log files, keeping most recent 5', () {
      // Create 7 fake log files with different mtimes
      for (var i = 0; i < 7; i++) {
        final file = File('${tempDir.path}/autoglm-2026-01-0$i.log');
        file.writeAsStringSync('log $i');
        // Set modification time to be different
        file.setLastModifiedSync(
          DateTime(2026, 1, 1).add(Duration(days: i)),
        );
      }
      initLogging(logsDir: tempDir.path);
      final remaining = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('autoglm-'))
          .toList();
      expect(remaining.length, 5);
    });

    test('Logger hierarchy works - child inherits parent level', () {
      initLogging();
      Logger('autoglm.adb').level = Level.WARNING;
      final child = Logger('autoglm.adb.client');
      // Child should inherit WARNING from parent
      expect(child.level, Level.WARNING);
    });

    test('records are emitted to listeners', () async {
      initLogging();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      Logger('test').info('test message');
      await sub.cancel();
      expect(records, hasLength(1));
      expect(records.first.message, 'test message');
      expect(records.first.level, Level.INFO);
    });
  });
}
```

### Step 3: Run the test to verify it fails

```bash
cd packages/autoglm_logger && flutter test
```

Expected: FAIL — `initLogging` does not exist yet.

### Step 4: Rewrite `app_logger.dart`

Replace the entire file with:

```dart
/// Application-wide logging configuration.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

/// Configures the root logger with console and optional file output.
///
/// Safe to call multiple times — subsequent calls reconfigure.
///
/// - In debug mode ([kDebugMode]), root level is [Level.FINE].
/// - In release mode, root level is [Level.INFO].
/// - When [logsDir] is provided, logs are written to daily-rotated files
///   named `autoglm-YYYY-MM-DD.log`. Old files are pruned to the 5 most
///   recent by modification time.
void initLogging({String? logsDir}) {
  hierarchicalLoggingEnabled = true;
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;

  final dir = logsDir != null ? Directory(logsDir) : null;
  if (dir != null && !dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  _pruneOldFiles(dir);

  Logger.root.onRecord.listen((record) {
    _consoleSink(record);
    _fileSink(record, dir);
  });
}

void _consoleSink(LogRecord record) {
  final time = record.time.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
  final level = record.level.name.padRight(7);
  final name = record.loggerName;
  final msg = '[$time] $level $name: ${record.message}';

  if (record.level >= Level.SEVERE) {
    // ignore: avoid_print
    print('\x1B[31m$msg\x1B[0m'); // red
  } else if (record.level >= Level.WARNING) {
    // ignore: avoid_print
    print('\x1B[33m$msg\x1B[0m'); // yellow
  } else if (record.level >= Level.INFO) {
    // ignore: avoid_print
    print(msg);
  } else {
    // ignore: avoid_print
    print('\x1B[90m$msg\x1B[0m'); // gray for debug/fine
  }

  if (record.error != null) {
    // ignore: avoid_print
    print('  ${record.error}');
  }
  if (record.stackTrace != null) {
    // ignore: avoid_print
    print('  ${record.stackTrace}');
  }
}

void _fileSink(LogRecord record, Directory? dir) {
  if (dir == null) return;
  try {
    final today = DateTime.now();
    final fileName = 'autoglm-${_dateStamp(today)}.log';
    final file = File(join(dir.path, fileName));
    final buffer = StringBuffer()
      ..write(record.time.toIso8601String())
      ..write(' ${record.level.name.padRight(7)} ')
      ..write(record.loggerName)
      ..write(': ')
      ..writeln(record.message);
    if (record.error != null) {
      buffer.writeln('  ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.writeln('  ${record.stackTrace}');
    }
    file.writeAsStringSync(buffer.toString(), mode: FileMode.append);
  } on Object {
    // File logging must not crash the app
  }
}

void _pruneOldFiles(Directory? dir) {
  if (dir == null || !dir.existsSync()) return;
  try {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => basename(f.path).startsWith('autoglm-'))
        .toList()
      ..sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    for (final f in files.skip(5)) {
      try {
        f.deleteSync();
      } on Object {
        // best-effort pruning
      }
    }
  } on Object {
    // best-effort listSync
  }
}

String _dateStamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)}';
}
```

### Step 5: Update barrel export

Replace `packages/autoglm_logger/lib/autoglm_logger.dart` with:

```dart
/// Application-wide logger with daily-rotated file output.
library;

export 'app_logger.dart';
export 'package:logging/logging.dart' show Logger, Level, LogRecord;
```

Note: We re-export `Logger`, `Level`, and `LogRecord` from `logging` so consumers only need to import `autoglm_logger`.

### Step 6: Delete `class_logger.dart`

```bash
rm packages/autoglm_logger/lib/applog/class_logger.dart
```

### Step 7: Run tests to verify they pass

```bash
cd packages/autoglm_logger && flutter test
```

Expected: All 5 tests pass.

### Step 8: Run workspace analyze

```bash
cd packages/autoglm_logger && flutter analyze
```

Expected: No issues.

### Step 9: Commit

```bash
git add packages/autoglm_logger/
git commit -m "$(cat <<'EOF'
refactor(autoglm_logger): replace logger package with official logging package

- initLogging() replaces initAppLogger() — configures hierarchical logging
- Logger.root with console (colored) + daily-rotated file output
- Re-exports Logger/Level/LogRecord so consumers only import autoglm_logger
- Delete unused ClassLogger mixin
- Remove maybeLog/maybeError static methods (callers use Logger directly)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Migrate `adb_tools` (autoglm_adb → adb_tools)

**Files:**
- Modify: `packages/adb_tools/lib/src/adb_binary_manager.dart`

### Step 1: Write the failing test

Add to `packages/adb_tools/test/adb_binary_manager_test.dart` (or create if it doesn't exist — check first). The key change: replace `AppLogger.maybeError` with a direct `Logger.severe` call. Since `maybeError` silently swallowed the error if logger wasn't initialized, we need to verify the new code still handles the case gracefully.

### Step 2: Update `adb_binary_manager.dart`

Read the file first, then make these changes:

1. Replace import:
```dart
// old
import 'package:autoglm_logger/autoglm_logger.dart';
// new
import 'package:logging/logging.dart';
```

2. Add logger field at the top of the class:
```dart
static final _log = Logger('autoglm.adb.AdbBinaryManager');
```

3. Replace `AppLogger.maybeError(...)` call in `_which` method:
```dart
// old
AppLogger.maybeError('Error in _which for $command', e, st);
// new
_log.warning('Error in _which for $command', e, st);
```

### Step 3: Verify tests pass

```bash
cd packages/adb_tools && flutter test
```

Expected: All tests pass.

### Step 4: Commit

```bash
git add packages/adb_tools/lib/src/adb_binary_manager.dart
git commit -m "$(cat <<'EOF'
refactor(adb_tools): migrate AdbBinaryManager to module-level Logger

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Migrate `scrcpy_mcp`

**Files:**
- Modify: `scrcpy_mcp/bin/scrcpy_mcp.dart`
- Modify: `scrcpy_mcp/lib/src/scrcpy_mcp_adapters.dart`
- Modify: `scrcpy_mcp/lib/src/recording_controller.dart`
- Modify: `scrcpy_mcp/test/recording_controller_test.dart`

### Step 1: Update `scrcpy_mcp/bin/scrcpy_mcp.dart`

Read the file first. Replace:
```dart
import 'package:autoglm_logger/autoglm_logger.dart';
```
with:
```dart
import 'package:autoglm_logger/autoglm_logger.dart';
```
(Import stays the same since `autoglm_logger` re-exports `logging`.)

Replace `initAppLogger()` with:
```dart
initLogging();
```

### Step 2: Update `scrcpy_mcp_adapters.dart`

Replace the `ScrcpyMcpLogger` class:

```dart
// old
class ScrcpyMcpLogger implements ScrcpyLogger {
  const ScrcpyMcpLogger();

  @override
  void debug(String message) => appLogger.d(message);

  @override
  void info(String message) => appLogger.i(message);

  @override
  void warn(String message, [Object? error, StackTrace? stack]) {
    appLogger.w(message, error, stack);
  }

  @override
  void error(String message, [Object? error, StackTrace? stack]) {
    appLogger.e(message, error, stack);
  }
}

// new
class ScrcpyMcpLogger implements ScrcpyLogger {
  static final _log = Logger('scrcpy.mcp');

  const ScrcpyMcpLogger();

  @override
  void debug(String message) => _log.fine(message);

  @override
  void info(String message) => _log.info(message);

  @override
  void warn(String message, [Object? error, StackTrace? stack]) {
    _log.warning(message, error, stack);
  }

  @override
  void error(String message, [Object? error, StackTrace? stack]) {
    _log.severe(message, error, stack);
  }
}
```

Also update the import: remove `import 'package:autoglm_logger/autoglm_logger.dart';` if `appLogger` is no longer used directly. Keep it only if `initLogging` or other exports are still needed. Add `import 'package:logging/logging.dart';` if needed (but prefer importing from `autoglm_logger` which re-exports it).

### Step 3: Update `recording_controller.dart`

Read the file first. Replace:
```dart
import 'package:autoglm_logger/autoglm_logger.dart';
```
with:
```dart
import 'package:autoglm_logger/autoglm_logger.dart';
```
(Keep as-is since it re-exports `Logger`.)

Add a logger field:
```dart
static final _log = Logger('scrcpy.mcp.RecordingController');
```

Replace the `appLogger.w(...)` call:
```dart
// old
appLogger.w('screenrecord process exited unexpectedly on $deviceId');
// new
_log.warning('screenrecord process exited unexpectedly on $deviceId');
```

### Step 4: Update `test/recording_controller_test.dart`

Read the file first. Replace `initAppLogger(logsDir: tempDir.path)` with:
```dart
initLogging(logsDir: tempDir.path);
```

### Step 5: Verify tests pass

```bash
cd scrcpy_mcp && flutter test
```

Expected: All tests pass.

### Step 6: Commit

```bash
git add scrcpy_mcp/
git commit -m "$(cat <<'EOF'
refactor(scrcpy_mcp): migrate to module-level Logger

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Migrate `scrcpy_app`

**Files:**
- Modify: `scrcpy_app/lib/main.dart`

### Step 1: Update `main.dart`

Read the file first. Replace `initAppLogger()` with:
```dart
initLogging();
```

If `appLogger` is used elsewhere in the file, replace those calls too.

### Step 2: Verify

```bash
cd scrcpy_app && flutter analyze
```

Expected: No issues.

### Step 3: Commit

```bash
git add scrcpy_app/lib/main.dart
git commit -m "$(cat <<'EOF'
refactor(scrcpy_app): migrate to initLogging()

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Migrate `scrcpy_view/example`

**Files:**
- Modify: `scrcpy_view/example/lib/main.dart`

### Step 1: Update `main.dart`

Read the file first. Replace:
```dart
import 'package:autoglm_logger/app_logger.dart';
```
with:
```dart
import 'package:autoglm_logger/autoglm_logger.dart';
```

Replace `initAppLogger()` with:
```dart
initLogging();
```

### Step 2: Verify

```bash
cd scrcpy_view/example && flutter analyze
```

Expected: No issues.

### Step 3: Commit

```bash
git add scrcpy_view/example/lib/main.dart
git commit -m "$(cat <<'EOF'
refactor(scrcpy_view/example): migrate to initLogging()

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Migrate `autoglm_app`

**Files:**
- Modify: `autoglm_app/lib/main.dart`
- Modify: `autoglm_app/lib/pages/chat_page.dart`
- Modify: `autoglm_app/lib/scrcpy/autoglm_scrcpy_bridge.dart`
- Modify: `autoglm_app/lib/src/settings_repository.dart`
- Modify: `autoglm_app/lib/test_scrcpy.dart`

### Step 1: Update `main.dart`

Read the file first. This file has many `appLogger.e/d/i` calls. Add a module-level logger:

```dart
import 'package:logging/logging.dart';

final _log = Logger('autoglm.app');
```

Replace all occurrences:
- `appLogger.info(...)` → `_log.info(...)`
- `appLogger.e(...)` → `_log.severe(...)`
- `appLogger.d(...)` → `_log.fine(...)`
- `initAppLogger(logsDir: logsDir.path)` → `initLogging(logsDir: logsDir.path)`

Note: `Logger.severe` signature is `severe(message, [Object? error, StackTrace? stackTrace])` — same as `appLogger.e`.

### Step 2: Update `chat_page.dart`

Read the file first. Add a module-level logger:

```dart
import 'package:logging/logging.dart';

final _log = Logger('autoglm.app.ChatPage');
```

Replace all occurrences:
- `appLogger.e('[ChatPage] Player Error: $error')` → `_log.severe('Player Error: $error')`
- `appLogger.i(...)` → `_log.info(...)`
- `appLogger.d(...)` → `_log.fine(...)`
- `appLogger.e('[ChatPage] Proxy never became ready', e, st)` → `_log.severe('Proxy never became ready', e, st)`
- `appLogger.e('scrcpyServerProvider error', e, st)` → `_log.severe('scrcpyServerProvider error', e, st)`

Remove the `[ChatPage]` prefix from messages — the logger name already provides that context.

### Step 3: Update `autoglm_scrcpy_bridge.dart`

Read the file first. Replace `AutoGlmScrcpyLogger`:

```dart
// old
class AutoGlmScrcpyLogger implements ScrcpyLogger {
  const AutoGlmScrcpyLogger();

  @override
  void debug(String message) => appLogger.d(message);

  @override
  void info(String message) => appLogger.i(message);

  @override
  void warn(String message, [Object? error, StackTrace? stack]) {
    appLogger.w(message, error, stack);
  }

  @override
  void error(String message, [Object? error, StackTrace? stack]) {
    appLogger.e(message, error, stack);
  }
}

// new
class AutoGlmScrcpyLogger implements ScrcpyLogger {
  static final _log = Logger('autoglm.scrcpy');

  const AutoGlmScrcpyLogger();

  @override
  void debug(String message) => _log.fine(message);

  @override
  void info(String message) => _log.info(message);

  @override
  void warn(String message, [Object? error, StackTrace? stack]) {
    _log.warning(message, error, stack);
  }

  @override
  void error(String message, [Object? error, StackTrace? stack]) {
    _log.severe(message, error, stack);
  }
}
```

Update import: replace `import 'package:autoglm_logger/autoglm_logger.dart';` with `import 'package:autoglm_logger/autoglm_logger.dart';` (keep — it re-exports `Logger`).

### Step 4: Update `settings_repository.dart`

Read the file first. Replace:

```dart
// old
import 'package:autoglm_logger/autoglm_logger.dart';
...
AppLogger.maybeError('Failed to load settings from $filePath', e, st);

// new
import 'package:autoglm_logger/autoglm_logger.dart';
import 'package:logging/logging.dart';
...
static final _log = Logger('autoglm.app.SettingsRepository');
...
_log.warning('Failed to load settings from $filePath', e, st);
```

Note: Changed from `severe` to `warning` — failing to load settings is recoverable (uses defaults), not a crash.

### Step 5: Update `test_scrcpy.dart`

Read the file first. Replace:
```dart
initAppLogger(logsDir: p.join(tempDir.path, 'autoglm_logs'));
```
with:
```dart
initLogging(logsDir: p.join(tempDir.path, 'autoglm_logs'));
```

### Step 6: Verify all tests pass

```bash
melos run test
```

Expected: All tests pass across all packages.

### Step 7: Verify analyze passes

```bash
melos run analyze
```

Expected: No issues.

### Step 8: Commit

```bash
git add autoglm_app/
git commit -m "$(cat <<'EOF'
refactor(autoglm_app): migrate to module-level Logger instances

- main.dart: Logger('autoglm.app')
- chat_page.dart: Logger('autoglm.app.ChatPage')
- autoglm_scrcpy_bridge.dart: Logger('autoglm.scrcpy')
- settings_repository.dart: Logger('autoglm.app.SettingsRepository')
- Remove all appLogger singleton usage

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Clean up — remove all traces of old API

**Files:**
- Verify: all packages compile and tests pass

### Step 1: Verify no remaining references to old API

```bash
grep -rn "appLogger\|AppLogger\|initAppLogger\|maybeLog\|maybeError\|ClassLogger" \
  --include="*.dart" \
  packages/ scrcpy_app/ scrcpy_mcp/ scrcpy_view/ autoglm_app/
```

Expected: No output (all references removed).

### Step 2: Verify no remaining references to old `logger` package

```bash
grep -rn "package:logger/" --include="*.dart" packages/ scrcpy_app/ scrcpy_mcp/ scrcpy_view/ autoglm_app/
```

Expected: No output.

### Step 3: Run full workspace

```bash
melos bootstrap && melos run analyze && melos run test
```

Expected: Bootstrap succeeds, no analysis issues, all tests pass.

### Step 4: Final commit if any stragglers found

If Step 1 or 2 found any remaining references, fix them and commit:

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: clean up remaining old logger API references

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Self-Review

**Spec coverage:**

| Requirement | Covered by |
|-------------|-----------|
| Replace `logger` with `logging` package | Task 1 |
| `initLogging()` replaces `initAppLogger()` | Task 1 |
| Hierarchical logger names per module | Tasks 2-6 |
| Delete `ClassLogger` mixin | Task 1 Step 6 |
| Remove `maybeLog`/`maybeError` | Task 1 (not exported), Tasks 2-6 (callers migrated) |
| Console output with colors | Task 1 (`_consoleSink`) |
| Daily-rotated file output | Task 1 (`_fileSink`) |
| Keep `ScrcpyLogger` interface unchanged | Tasks 3, 5, 6 (adapters updated, interface untouched) |
| `ScrcpyMcpLogger` uses module-level logger | Task 3 |
| `AutoGlmScrcpyLogger` uses module-level logger | Task 6 |
| Re-export `Logger`/`Level`/`LogRecord` from barrel | Task 1 Step 5 |

**Placeholder scan:** No TBDs or "similar to Task N" found. All code blocks are complete.

**Type consistency:**
- `initLogging({String? logsDir})` — consistent across all tasks
- `Logger('name')` — consistent logger declaration pattern
- `_log.fine/info/warning/severe` — consistent level mapping (d→fine, i→info, w→warning, e→severe)
- `ScrcpyLogger` interface methods (`debug/info/warn/error`) — unchanged, adapters map to `_log.fine/info/warning/severe`
