import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:autoglm_scrcpy/src/scrcpy_packet.dart';

/// A proxy that serves H264 NALUs over HTTP for better player compatibility.
class ScrcpyProxyServer {
  HttpServer? _server;
  StreamSubscription<ScrcpyPacket>? _subscription;
  
  // Clients currently receiving the live HTTP stream.
  final List<HttpResponse> _clients = [];
  
  // Clients waiting for the next I-Frame.
  final List<HttpResponse> _pendingClients = [];
  
  ScrcpyPacket? _configPacket;
  int _port = 0;
  final Completer<void> _readyCompleter = Completer<void>();

  /// The HTTP URL that the media player should connect to.
  String get mediaUrl => 'http://127.0.0.1:$_port/live';

  /// Resolves after at least one SPS/PPS has been seen.
  Future<void> get ready => _readyCompleter.future;

  /// Starts the proxy server by listening on a local HTTP port.
  Future<void> start(Stream<ScrcpyPacket> packets) async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    print('[ScrcpyProxyServer] HTTP Media server ready on $mediaUrl');

    _server!.listen((HttpRequest request) async {
      if (request.uri.path != '/live') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      print('[ScrcpyProxyServer] New HTTP client from ${request.connectionInfo?.remoteAddress.address}');
      
      final response = request.response;
      response.headers.contentType = ContentType('video', 'h264');
      response.headers.set('Connection', 'keep-alive');
      response.headers.set('Cache-Control', 'no-cache');
      
      _pendingClients.add(response);
      
      // Keep connection open until client disconnects
      unawaited(response.done.then((_) {
        print('[ScrcpyProxyServer] HTTP client disconnected');
        _activeClients_remove(response);
      }).catchError((Object _) {
        _activeClients_remove(response);
      }));
    });

    _subscription = packets.listen((packet) {
      if (packet.type == ScrcpyPacketType.configuration) {
        _configPacket = packet;
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        return;
      }

      final isKey = packet.isKeyFrame;
      final builder = BytesBuilder();
      _appendPacketToBuilder(builder, packet);
      final rawData = builder.takeBytes();

      if (isKey && _configPacket != null) {
        final burstBuilder = BytesBuilder();
        _appendPacketToBuilder(burstBuilder, _configPacket!);
        _appendPacketToBuilder(burstBuilder, packet);
        final burstData = burstBuilder.takeBytes();

        for (final response in List<HttpResponse>.from(_pendingClients)) {
          try {
            response.add(burstData);
            _clients.add(response);
          } catch (_) {
            response.close();
          }
        }
        _pendingClients.clear();
      }

      // Broadcast live data
      for (final response in List<HttpResponse>.from(_clients)) {
        try {
          response.add(rawData);
        } catch (e) {
          response.close();
          _clients.remove(response);
        }
      }
    });
  }

  void _activeClients_remove(HttpResponse res) {
    _clients.remove(res);
    _pendingClients.remove(res);
  }

  void _appendPacketToBuilder(BytesBuilder builder, ScrcpyPacket packet) {
    if (packet.data.isEmpty) return;
    if (!_hasStartCode(packet.data)) {
      builder.add(const [0x00, 0x00, 0x00, 0x01]);
    }
    builder.add(packet.data);
  }

  bool _hasStartCode(Uint8List data) {
    if (data.length < 4) return false;
    return (data[0] == 0 && data[1] == 0 && data[2] == 0 && data[3] == 1) ||
           (data[0] == 0 && data[1] == 0 && data[2] == 1);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    for (final res in [..._clients, ..._pendingClients]) {
      await res.close();
    }
    _clients.clear();
    _pendingClients.clear();
    await _server?.close(force: true);
    _server = null;
    _configPacket = null;
  }
}
