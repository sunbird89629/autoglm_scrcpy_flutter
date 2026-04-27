import 'dart:async';

import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy/autoglm_scrcpy.dart';
import 'package:autoglm_scrcpy_example/webview/harness_controller.dart';
import 'package:autoglm_scrcpy_example/webview/harness_scope.dart';
import 'package:autoglm_scrcpy_example/webview/screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void launchWebView() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();

  final tempDir = await getTemporaryDirectory();
  initAppLogger(logsDir: p.join(tempDir.path, 'autoglm_logs'));

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ScrcpyWebViewTestScreen(),
    ),
  );
}

class ScrcpyWebViewTestScreen extends StatefulWidget {
  const ScrcpyWebViewTestScreen({super.key});

  @override
  State<ScrcpyWebViewTestScreen> createState() =>
      _ScrcpyWebViewTestScreenState();
}

class _ScrcpyWebViewTestScreenState extends State<ScrcpyWebViewTestScreen> {
  late final WebViewHarnessController _controller = WebViewHarnessController();
  Timer? _autoStartTimer;

  @override
  void initState() {
    super.initState();
    _autoStartTimer = Timer(const Duration(seconds: 2), () {
      if (!_controller.isRunning) {
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebViewHarnessScope(
      controller: _controller,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        appBar: AppBar(
          title: const Text('Scrcpy InAppWebView (AutoGLM)'),
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white,
        ),
        body: const Row(
          children: [
            Expanded(child: ScreenView()),
            _ControlView(),
          ],
        ),
      ),
    );
  }
}

class _ControlView extends StatelessWidget {
  const _ControlView();

  @override
  Widget build(BuildContext context) {
    final controller = WebViewHarnessScope.of(context);
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo[800],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          controller.isRunning ? null : controller.start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      key: const Key('stop_button'),
                      onPressed:
                          controller.isRunning ? controller.stop : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[900],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (controller.isRunning) ...[
                  const Divider(color: Colors.white24, height: 24),
                  const Text(
                    'Remote Control',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlBtn(Icons.arrow_back,
                          () => controller.injectKey(ScrcpyKeycode.back)),
                      _controlBtn(Icons.circle_outlined,
                          () => controller.injectKey(ScrcpyKeycode.home)),
                      _controlBtn(Icons.menu,
                          () => controller.injectKey(ScrcpyKeycode.appSwitch)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: controller.logs.length,
                itemBuilder: (context, index) => Text(
                  controller.logs[index],
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
