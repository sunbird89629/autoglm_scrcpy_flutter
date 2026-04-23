import 'dart:async';

import 'package:autoglm_adb/autoglm_adb.dart';
import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy/autoglm_scrcpy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
// Import media_kit
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  // Enable driver extension
  enableFlutterDriverExtension();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit
  MediaKit.ensureInitialized();

  // Initialize the logger for the test
  final tempDir = await getTemporaryDirectory();
  initAppLogger(logsDir: p.join(tempDir.path, 'autoglm_logs'));

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScrcpyTestScreen(),
    ),
  );
}

class ScrcpyTestScreen extends StatefulWidget {
  const ScrcpyTestScreen({super.key});

  @override
  State<ScrcpyTestScreen> createState() => _ScrcpyTestScreenState();
}

class _ScrcpyTestScreenState extends State<ScrcpyTestScreen> {
  final List<String> _logs = [];
  ScrcpyServer? _server;
  bool _isRunning = false;

  // media_kit variables
  late final Player _player = Player(
    configuration: const PlayerConfiguration(
      bufferSize: 0, // Minimize latency
    ),
  );
  late final VideoController _controller = VideoController(_player);

  @override
  void initState() {
    super.initState();

    // Set low-latency and raw format options for libmpv globally
    if (_player.platform is NativePlayer) {
      final native = _player.platform! as NativePlayer;
      native.setProperty('demuxer-lavf-format', 'h264');
      native.setProperty('demuxer-lavf-probsize', '32');
      native.setProperty('demuxer-lavf-analyzeduration', '0');
      native.setProperty('fps', '60'); // Hint to avoid probe delay
      native.setProperty('profile', 'low-latency');
      native.setProperty('untimed', 'yes');
      native.setProperty('cache', 'no');
      native.setProperty('video-sync', 'desync');
      native.setProperty('vd-lavc-threads', '1');
    }

    // Listen for all player events for better debugging
    _player.stream.videoParams.listen((params) {
      _addLog('Video Params: ${params.w}x${params.h} aspect=${params.aspect}');
    });

    _player.stream.playing.listen((playing) {
      _addLog('Player Playing: $playing');
    });

    _player.stream.buffering.listen((buffering) {
      if (buffering) _addLog('Player Buffering...');
    });
  }

  void _addLog(String message) {
    debugPrint(message);
    setState(() {
      _logs.add(
          '${DateTime.now().toIso8601String().split('T').last.substring(0, 8)}: $message');
    });
  }

  Future<void> _startTest() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    const adbClient = AdbClient();

    try {
      _addLog('Searching for devices...');
      final devices = await adbClient.devices();
      if (devices.isEmpty) {
        _addLog('Error: No devices found!');
        setState(() => _isRunning = false);
        return;
      }

      final deviceId = devices.first;
      _addLog('Using device: $deviceId');

      _server = ScrcpyServer(
        adbClient: adbClient,
        deviceId: deviceId,
      );

      _server!.metadata.listen((meta) {
        _addLog('Metadata: ${meta.deviceName} (${meta.width}x${meta.height})');
      });

      var packetCount = 0;
      _server!.packets.listen((packet) {
        packetCount++;
        if (packetCount % 60 == 0) {
          _addLog('Received $packetCount packets...');
        }
      });

      _addLog('Starting server...');
      await _server!.start();

      _addLog('Server started! Proxy: ${_server!.proxyUrl}');

      _addLog('Waiting for proxy to be ready...');
      await _server!.proxyReady.timeout(const Duration(seconds: 10));

      _addLog('READY: Opening stream in app...');

      // Now using the HTTP proxy which provides 'video/h264' content-type.
      // We still use ffmpeg: prefix as it's the most reliable way to
      // handle containerless H264 on macOS.
      final forcedUrl = 'ffmpeg:${_server!.proxyUrl}';
      _addLog('Opening HTTP stream: $forcedUrl');

      await _player.open(
        Media(forcedUrl),
      );

      _player.setRate(1);
      _player.setVolume(0);
    } catch (e, st) {
      _addLog('Fatal error: $e');
      debugPrintStack(stackTrace: st);
      setState(() => _isRunning = false);
    }
  }

  Future<void> _stopTest() async {
    await _player.stop();
    await _server?.stop();
    _addLog('Server stopped.');
    setState(() {
      _isRunning = false;
      _server = null;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('AutoGLM Scrcpy In-App Preview'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left Side: Controls and Logs
          SizedBox(
            width: 350,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueGrey[800],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _startTest,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _stopTest : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => Text(
                        _logs[index],
                        style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Side: Live Video Preview
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border:
                    Border(left: BorderSide(color: Colors.white10, width: 2)),
              ),
              child: Center(
                child: _isRunning
                    ? Video(
                        controller: _controller,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phonelink_setup,
                              size: 64, color: Colors.blueGrey[700]),
                          const SizedBox(height: 16),
                          Text('Press START to mirror screen',
                              style: TextStyle(
                                  color: Colors.blueGrey[700], fontSize: 18)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
