import 'package:scrcpy_view/src/control_message.dart';

/// Abstraction over a scrcpy mirroring session.
///
/// Decouples consumers (e.g. MCP server) from the Flutter-specific
/// view controller, so they only depend on the device-control
/// contract rather than a UI-layer class.
abstract class ScrcpySession {
  /// Whether a mirroring session is currently active.
  bool get isConnected;

  /// HTTP proxy URL for MPEG-TS stream, or `null` if no session.
  String? get proxyUrl;

  /// WebSocket URL for the web player, or `null` if no session.
  String? get playerUrl;

  /// Starts a mirroring session for [deviceId].
  Future<void> start(String deviceId);

  /// Stops the active mirroring session.
  Future<void> stop();

  /// Sends a raw control message to the device.
  void sendControlMessage(ScrcpyControlMessage message);

  /// Injects text into the focused field on the device.
  void injectText(String text);
}
