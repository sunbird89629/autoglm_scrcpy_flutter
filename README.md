# Scrcpy Flutter

Scrcpy Flutter is a macOS-first Flutter desktop workspace for Android device
automation. It combines ADB device management, scrcpy-based screen mirroring,
input control, and MCP server surfaces so local tools and agents can inspect
and operate an Android device.

## Status

The project is under active development. The reusable ADB wrapper, scrcpy
protocol layer, standalone scrcpy desktop app, and MCP server package are
available. macOS is the only verified target at the moment; Windows and Linux
support are planned after the macOS path is stable.

## Features

- Android device discovery and command execution through ADB
- Scrcpy server lifecycle management and H.264 stream handling
- WebView-based Android screen preview with touch, key, text, scroll, and
  navigation controls
- Standalone `scrcpy_app` / `scrcpy_flutter` desktop clients for local
  mirroring experiments
- `scrcpy_plus` macOS menu-bar app for device management + scrcpy launcher
- `scrcpy_mcp` server exposing device and mirroring operations over MCP

## Prerequisites

- macOS (only verified target for now)
- Flutter SDK ≥ 3.24
- Dart SDK ≥ 3.5

## Setup

```bash
# 1. Install melos
dart pub global activate melos

# 2. Bootstrap the workspace
melos bootstrap

# 3. Generate code
melos run gen          # freezed / json_serializable
melos run gen:i18n     # slang strings.g.dart

# 4. Verify
melos run analyze      # expect: 0 issues
melos run format       # expect: no diff
melos run test         # expect: all green

# 5. Run the app
cd scrcpy_flutter && flutter run -d macos
```

## Current Project Map

```
scrcpy_flutter/        # Main Scrcpy Flutter desktop client (mirroring + MCP panel)
  lib/
    theme/
    views/             # Control overlay widgets
    widgets/
  pubspec.yaml

scrcpy_plus/           # macOS menu-bar app for device management + scrcpy launcher
  lib/
    app/               # AppController
    device/
    mcp/               # McpServerController
    scrcpy/            # Adapter: AdbClient → ScrcpyAdb
    settings/          # SettingsManager (JSON config)
  pubspec.yaml

scrcpy_app/            # Standalone scrcpy client (mirroring + MCP panel)
  lib/
    app_controller.dart        # Wires ScrcpyViewController + McpServerController
    home_page.dart             # Viewer + controls + MCP panel layout
    mcp_server_controller.dart # McpHttpServer lifecycle (port, URL, error state)
    mcp_server_panel.dart      # Start/stop UI + copy URL
    device_list_widget.dart
    scrcpy_app_adb.dart        # AdbClient → ScrcpyAdb adapter
    views/                     # Control overlay widgets
    widgets/
  macos/
  pubspec.yaml

scrcpy_view/           # Reusable package: scrcpy protocol + WebView widget
  lib/
    scrcpy_view.dart   # Public exports
    src/
      scrcpy_server.dart           # Server lifecycle: push JAR, ADB forward, sockets
      scrcpy_stream_parser.dart    # Binary frame parser (PTS + length frames)
      scrcpy_proxy_server.dart     # H.264 → MPEG-TS HTTP proxy
      scrcpy_websocket_server.dart # WebSocket player + SPS/PPS injection
      control_message.dart         # Scrcpy v3 control protocol
      mpeg_ts_muxer.dart           # 188-byte MPEG-TS muxer
      backends/
  assets/
    scrcpy-server-v3.3.4
    web_player/
  example/
  test/
  pubspec.yaml

scrcpy_mcp/            # MCP server wrapping scrcpy operations
  lib/
    scrcpy_mcp.dart
    src/
      scrcpy_mcp_server.dart   # 8 tools, 2 resources, 2 prompts
      mcp_http_server.dart     # StreamableMcpServer HTTP wrapper
      scrcpy_mcp_adapters.dart # AdbClient → ScrcpyAdb adapter
  bin/
    scrcpy_mcp_test.dart       # Stdio MCP CLI entry point
  test/
  pubspec.yaml

packages/
  adb_tools/           # ADB binary lifecycle and command wrapper
    lib/
      src/
        adb_binary_manager.dart  # Downloads/caches platform-tools
        adb_client.dart          # shell, forward, push, pair, connect, getDevicesWithInfo
        adb_process_runner.dart
        device_info.dart         # DeviceInfo + DeviceStatus enum
        exceptions.dart
    test/

  scrcpy_client/       # Pure-Dart scrcpy protocol client (ADB orchestration,
    lib/               # socket comms, stream parsing, control injection)
    test/

pubspec.yaml           # Dart workspace root, package list, and Melos scripts
analysis_options.yaml  # Root analyzer configuration
```

> `logger_utils` (logging facade) lives in a sibling repo and is pulled in via
> a relative `path:` dependency (`../../logger_utils`), not under `packages/`.

## TODO

### Phase 2 — Device Management

- [ ] Pairing/connect flow: validation, loading state, success/failure snackbar, post-pair auto-refresh
- [ ] ADB error state handling: unauthorized prompt, offline retry, missing ADB binary, failed platform-tools download
- [ ] Device connect/disconnect notification (auto-refresh or stream-based)
- [ ] Tests: `AdbBinaryManager` lifecycle, provider refresh, device selection edge cases

### Phase 3 — Scrcpy Mirroring

- [ ] Idempotent `ScrcpyServer.start()` / `stop()` — survive partial startup failure without leaving zombie processes
- [ ] Surface stream errors, proxy readiness status, and server logs in the UI
- [ ] Reconnect/restart button when device disconnects or scrcpy process exits unexpectedly
- [ ] Verify touch coordinate mapping and all control messages against a real device
- [ ] Tests: packet fragmentation, keyframe injection timing, multi-client proxy connection

### Phase 4 — Desktop App Shell

- [ ] Desktop app device sidebar: selected-device details, stream status, start/stop mirroring button
- [ ] `ChatPage`: screen preview panel, task input, live execution log, agent state indicator
- [ ] `HistoryPage`: search bar, date/status filters, step detail panel, trace timing view
- [ ] `SettingsPage`: LLM provider / model / base URL / API key, MCP server toggle + port, logs path, diagnostics

### Phase 5 — Agent Execution Loop

- [ ] Define agent runtime: task request → screen observe → tool call → result → trace span → history step
- [ ] First tool set: screenshot, tap, swipe, type, key event, wait, shell command
- [ ] Persist runs as conversation + steps + trace so failures are inspectable
- [ ] Cancellation, timeouts, and explicit agent state in the UI

---

## Roadmap

| Phase | Area | Status | Goal |
|---|---|---|---|
| 0 | Monorepo foundation | done | Keep `scrcpy_view`, `scrcpy_mcp`, `scrcpy_app`/`scrcpy_flutter`/`scrcpy_plus`, and shared packages bootstrapped through Melos with analyze/format/test scripts. |
| 1 | Core services | mostly done | Maintain settings, logging, ADB process execution, trace records, and history storage as stable lower-level packages. |
| 2 | Device management | in progress | Make Android device discovery, selection, wireless pairing, connect/disconnect, and error recovery production-ready. |
| 3 | Scrcpy mirroring | in progress | Stabilize server deployment, socket lifecycle, H.264 parsing, MPEG-TS proxying, video playback, and input control. |
| 4 | Desktop app shell | in progress | Replace placeholder sidebars/pages with real device state, stream status, session state, and actionable controls. |
| 5 | Agent execution loop | planned | Connect chat input to an LLM/tool loop that can observe the device screen, issue ADB/scrcpy control actions, and record steps. |
| 6 | Workflows | planned | Add reusable automation workflows, workflow runs, run history, cancellation, retry, and parameter editing. |
| 7 | MCP integration | planned | Expose device, screen, control, history, and workflow operations as MCP tools with clear lifecycle ownership. |
| 8 | Product hardening | planned | Add tests, diagnostics, onboarding, localization polish, packaging, update strategy, and cross-platform preparation. |

### Phase Details

**Phase 2: Device Management**

Done:
- Rich device info display: model name, manufacturer, Android version, connection type (USB / Wi-Fi icon), and online / offline / unauthorized status badge (`DeviceInfo`, `getDevicesWithInfo()`, `adbDevicesWithInfoProvider`)

Remaining:
- Pairing/connect flows: validation, loading states, success/failure feedback, and post-pair refresh
- ADB error state handling: unauthorized, offline, multiple devices, missing ADB binary, failed platform-tools download
- Auto-refresh or device-connect/disconnect notification
- Focused tests for `AdbBinaryManager`, provider refresh, and device selection edge cases

**Phase 3: Scrcpy Mirroring**

Done:
- `ScrcpyAdb.takeScreenshot()` via ADB `exec-out screencap`
- `McpHttpServer` / `McpServerController` / `McpServerPanel` in `scrcpy_app` — HTTP MCP server with start/stop UI
- MCP tools: `list_devices`, `start_mirroring`, `stop_mirroring`, `inject_key/touch/text/scroll`, `take_screenshot`
- WebSocket-based web player for H.264 preview

Remaining:
- Idempotent `ScrcpyServer.start()` / `stop()` resilient to partial startup failure
- Surface stream errors, proxy readiness, and server logs in the UI
- Reconnect/restart controls when the device disconnects or the scrcpy process exits
- Verify touch coordinate mapping and control messages against a real device
- Parser/proxy tests for packet fragmentation, keyframe injection, and client connection timing

**Phase 4: Desktop App Shell**

Done:
- `DevicesPage` rewritten with rich device cards (model, status, connection type)

Remaining:
- Device sidebar in the desktop app shell: selected-device details, stream status, and quick controls
- Turn `ChatPage` into the main operation workspace: screen preview, task input, execution log, and agent state indicator
- Expand `HistoryPage` with search, filters, details panel, and step replay/debug view
- Expand `SettingsPage` for provider/model/base URL/API key, MCP server settings, logs path, and diagnostics

**Phase 5: Agent Execution Loop**
- Define the agent runtime boundary: task request, screen observation, tool call, result, trace span, history step.
- Implement first tool set: screenshot/observe, tap, swipe, text input, key event, wait, shell command.
- Persist each run as conversation + steps + trace timing so failures can be inspected.
- Add cancellation/timeouts and make agent state explicit in the UI.

**Phase 6: Workflows**
- Define workflow model: name, description, parameters, steps, target app/device constraints.
- Build create/edit/run UI on `WorkflowsPage`.
- Store workflow definitions and workflow run records.
- Support run cancellation, retry from failed step, and export/import later if needed.

**Phase 7: MCP Integration**
- Promote `scrcpy_mcp` from wrapper to a lifecycle-aware server surface.
- Expose safe MCP tools for listing devices, starting/stopping mirroring, observing screen state, sending controls, and reading history.
- Add guardrails so MCP calls cannot fight the UI for ownership of the same active device session.

**Phase 8: Product Hardening**
- Add widget/integration coverage for the main desktop flows.
- Improve logs and diagnostics screens so users can report actionable failures.
- Package the macOS app and document signing/notarization expectations.
- Prepare Windows/Linux support only after the macOS ADB/scrcpy path is stable.

## Monorepo (Melos)

This repo uses Dart 3.5+ pub workspaces with [Melos](https://melos.invertase.dev/) for task orchestration — all packages share one resolved dependency tree.

### Daily commands

```bash
melos bootstrap             # bs — install deps + link local packages
                            # rerun after pulling or editing any pubspec.yaml
melos run analyze           # static analysis across all packages
melos run format            # check formatting (no changes)
melos run format:fix        # apply formatting
melos run test              # run all tests
melos run gen               # build_runner (freezed / json_serializable)
melos run gen:i18n          # regenerate slang strings.g.dart
```

## Testing

The default test command is CI-friendly and only runs packages that have a
`test/` directory:

```bash
melos run test
```

Current test coverage:

| Package | Test focus |
|---|---|
| `packages/adb_tools` | ADB command parsing, process runner, binary manager, `getDevicesWithInfo()` parsing and degradation |
| `scrcpy_view` | Control message encoding, server wiring, stream parser |
| `scrcpy_mcp` | MCP tool/resource/prompt contracts, HTTP server lifecycle |
| `scrcpy_plus` | Settings manager, device management |

Packages without a `test/` directory are skipped by the default command.
ADB tests that require a real Android device should stay skipped by default or
move to a separately triggered integration test workflow.

### Scoping to specific packages

Scripts run in every package by default. Narrow with `--scope` / `--ignore`:

```bash
melos run analyze --scope="adb_tools"
melos run test --scope="scrcpy_*"           # glob match
melos run test --ignore="scrcpy_app"
```

### Adding dependencies

Because of pub workspaces, add dependencies inside the target package, not at the root:

```bash
cd packages/adb_tools
dart pub add some_package
cd - && melos bootstrap                     # refresh links
```

### Diagnostics

```bash
melos list                  # list all packages
melos list --graph          # dependency graph (JSON) — useful for spotting cycles
melos clean                 # nuke .dart_tool + pubspec.lock; follow with `melos bs`
```

### Conventions

- One PR can span `packages/*`, `scrcpy_app`, `scrcpy_flutter`, `scrcpy_plus`, `scrcpy_view`, and `scrcpy_mcp` when a feature crosses package boundaries.
- Lower layers (`packages/adb_tools`, `scrcpy_view`) must not import from upper application layers; verify with `melos list --graph`.
- Open the IDE at the repo root so cross-package navigation works.

## Settings file

`scrcpy_plus` persists config under `~/Library/Application Support/scrcpy_plus/`:
- `settings.json` — app settings
- `known_devices.json` — known device serials
