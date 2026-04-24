import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy/src/scrcpy_packet.dart';

/// A proxy that serves H264 NALUs over a raw TCP socket.
class ScrcpyProxyServer {
  ServerSocket? _server;
  StreamSubscription<ScrcpyPacket>? _subscription;
  
  final List<Socket> _activeClients = [];
  final List<Socket> _pendingClients = [];
  
  ScrcpyPacket? _configPacket;
  int _port = 0;
  final Completer<void> _readyCompleter = Completer<void>();

  /// The URL for the media player to connect to.
  String get proxyUrl => 'tcp://127.0.0.1:$_port';

  /// Resolves when the proxy has received the configuration packet (SPS/PPS).
  Future<void> get ready => _readyCompleter.future;

  /// Starts the proxy server.
  Future<void> start(Stream<ScrcpyPacket> packets) async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    appLogger.i('[ScrcpyProxyServer] TCP Media server ready on $proxyUrl');

    _server!.listen((Socket client) {
      appLogger.i('[ScrcpyProxyServer] New TCP client connected: ${client.remoteAddress}:${client.remotePort}');
      // New clients wait for the next IDR keyframe to ensure they start at a decodable point.
      _pendingClients.add(client);
      
      client.listen(
        (_) {}, // ignore incoming
        onDone: () => _removeClient(client),
        onError: (e) {
          appLogger.w('[ScrcpyProxyServer] Client error: $e');
          _removeClient(client);
        },
      );
    });

    _subscription = packets.listen((packet) {
      if (packet.type == ScrcpyPacketType.configuration) {
        appLogger.i('[ScrcpyProxyServer] Received configuration packet (${packet.data.length} bytes)');
        _configPacket = packet;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        return;
      }

      final isKey = packet.isKeyFrame;
      final builder = BytesBuilder();
      _appendPacketToBuilder(builder, packet);
      final rawData = builder.takeBytes();

      // 1. If it's a keyframe and we have config, "welcome" any pending clients
      if (isKey && _configPacket != null) {
        final burstBuilder = BytesBuilder();
        _appendPacketToBuilder(burstBuilder, _configPacket!);
        _appendPacketToBuilder(burstBuilder, packet);
        final burstData = burstBuilder.takeBytes();

        if (_pendingClients.isNotEmpty) {
          appLogger.i('[ScrcpyProxyServer] IDR Keyframe: flushing ${_pendingClients.length} pending clients');
          for (final client in List<Socket>.from(_pendingClients)) {
            try {
              client.add(burstData);
              _activeClients.add(client);
            } catch (e) {
              client.destroy();
            }
          }
          _pendingClients.clear();
        }
      }

      // 2. Always send the current packet to all ALREADY active clients
      for (final client in List<Socket>.from(_activeClients)) {
        try {
          client.add(rawData);
        } catch (e) {
          appLogger.w('[ScrcpyProxyServer] Client write error: $e');
          client.destroy();
          _activeClients.remove(client);
        }
      }
    });
  }

  void _removeClient(Socket client) {
    _activeClients.remove(client);
    _pendingClients.remove(client);
  }

  void _appendPacketToBuilder(BytesBuilder builder, ScrcpyPacket packet) {
    if (packet.data.isEmpty) return;
    
    final data = packet.data;
    bool hasStartCode = false;
    if (data.length >= 3 && data[0] == 0 && data[1] == 0 && data[2] == 1) {
      hasStartCode = true;
    } else if (data.length >= 4 && data[0] == 0 && data[1] == 0 && data[2] == 0 && data[3] == 1) {
      hasStartCode = true;
    }

    if (!hasStartCode) {
      builder.add(const [0x00, 0x00, 0x00, 0x01]);
    }
    builder.add(packet.data);
  }

  /// Stops the proxy server.
  Future<void> stop() async {
    await _subscription?.cancel();
    for (final client in [..._activeClients, ..._pendingClients]) {
      client.destroy();
    }
    _activeClients.clear();
    _pendingClients.clear();
    await _server?.close();
    _server = null;
    _configPacket = null;
  }
}
