import 'dart:async';

import 'package:autoglm_scrcpy_example/webview/screen_view.dart';
import 'package:autoglm_scrcpy_example/webview/ui/control_view.dart';
import 'package:autoglm_scrcpy_example/webview/harness_controller.dart';
import 'package:autoglm_scrcpy_example/webview/harness_scope.dart';
import 'package:flutter/material.dart';

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
            ControlView(),
          ],
        ),
      ),
    );
  }
}
