# scrcpy_plus

MCP server for [scrcpy](https://github.com/Genymobile/scrcpy) — Android screen mirroring and device control via the [Model Context Protocol](https://modelcontextprotocol.io/).

Built with [dart_mcp](https://pub.dev/packages/dart_mcp).

## Features

### Tools

| Tool | Description | Parameters |
|------|-------------|------------|
| `list_devices` | List connected Android devices | — |
| `start_mirroring` | Start screen mirroring | `device_id` (required) |
| `stop_mirroring` | Stop the active session | — |
| `inject_key` | Send a key event | `keycode` (required), `action` (optional) |
| `inject_touch` | Send a touch event | `x`, `y`, `width`, `height` (required), `action` (optional) |
| `inject_text` | Input text | `text` (required) |
| `inject_scroll` | Send a scroll event | `x`, `y`, `width`, `height`, `hScroll`, `vScroll` (required) |

**Key actions:** `0` = down, `1` = up (default: `0`)

**Touch actions:** `0` = down, `1` = up, `2` = move (default: `0`)

**Common keycodes:** `3` = Home, `4` = Back, `187` = App Switch

### Resources

| URI | Description | Format |
|-----|-------------|--------|
| `device://list` | Connected device list | JSON array |
| `mirroring://status` | Current mirroring status | JSON object |

**Mirroring status example:**
```json
{
  "active": true,
  "device_id": "emulator-5554",
  "proxy_url": "http://127.0.0.1:27183",
  "player_url": "http://127.0.0.1:27184"
}
```

### Prompts

| Prompt | Description | Arguments |
|--------|-------------|-----------|
| `control_device` | Device control assistant | `device_id` (optional) |
| `troubleshoot` | Device troubleshooting assistant | `issue` (optional) |

## Usage

### As a CLI tool

```bash
# Run with default adb path
dart run scrcpy_plus/bin/scrcpy_plus.dart

# Run with custom adb path
dart run scrcpy_plus/bin/scrcpy_plus.dart /path/to/adb
```

Configure your MCP client to launch this command. For example, in Claude Code's `settings.json`:

```json
{
  "mcpServers": {
    "scrcpy": {
      "command": "dart",
      "args": ["run", "scrcpy_plus/bin/scrcpy_plus.dart"]
    }
  }
}
```

### As a library

```dart
import 'package:scrcpy_plus/scrcpy_plus.dart';
import 'package:stream_channel/stream_channel.dart';

// Create server with a StreamChannel for MCP transport
final server = ScrcpyPlusServer(
  channel,
  adb: ScrcpyPlusAdb(adbClient),
);

// Wait for server to finish
await server.done;
```

#### Using adapters

The package includes adapters for bridging `autoglm_adb` to `scrcpy_view`:

```dart
import 'package:autoglm_adb/autoglm_adb.dart';
import 'package:scrcpy_plus/scrcpy_plus.dart';

final adbClient = AdbClient(adbPath: 'adb');
final scrcpyAdb = ScrcpyPlusAdb(adbClient);

final server = ScrcpyPlusServer(
  channel,
  adb: scrcpyAdb,
);
```

## Architecture

```
scrcpy_plus
├── lib/
│   ├── scrcpy_plus.dart              # Library exports
│   └── src/
│       ├── scrcpy_plus_server.dart    # MCPServer implementation
│       └── scrcpy_plus_adapters.dart  # ADB/Logger adapters
├── bin/
│   └── scrcpy_plus.dart              # CLI entry point
└── test/
    └── scrcpy_plus_server_test.dart   # Unit tests
```

## Development

```bash
# Install dependencies
melos bootstrap

# Run tests
cd scrcpy_plus && flutter test

# Run analyzer
cd scrcpy_plus && dart analyze

# Run CLI
dart run scrcpy_plus/bin/scrcpy_plus.dart
```

## Dependencies

- [dart_mcp](https://pub.dev/packages/dart_mcp) — MCP protocol implementation
- [scrcpy_view](../scrcpy_view) — Scrcpy widget/protocol package
- [autoglm_adb](../packages/autoglm_adb) — ADB client

## License

Apache-2.0
