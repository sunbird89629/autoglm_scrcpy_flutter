import 'package:mcp_dart/mcp_dart.dart';
import 'package:scrcpy_client/scrcpy_client.dart';
import 'package:scrcpy_plus/src/recording_adb.dart';
import 'package:scrcpy_plus/src/scrcpy_plus_server.dart';

class McpHttpServer {
  StreamableMcpServer? _server;
  int? _port;

  String? get serverUrl => _port != null ? 'http://localhost:$_port/mcp' : null;

  Future<void> start({
    required int port,
    required ScrcpySession session,
    required ScrcpyAdb adb,
    RecordingAdb? recordingAdb,
  }) async {
    _server = StreamableMcpServer(
      serverFactory: (_) => ScrcpyPlusServer(
        session: session,
        adb: adb,
        recordingAdb: recordingAdb,
      ).mcpServer,
      port: port,
      enableDnsRebindingProtection: false,
    );
    await _server!.start();
    _port = port;
  }

  Future<void> stop() async {
    await _server?.stop();
    _server = null;
    _port = null;
  }
}
