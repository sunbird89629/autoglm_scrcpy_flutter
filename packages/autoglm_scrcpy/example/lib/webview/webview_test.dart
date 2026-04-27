import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy_example/webview/ui/scrcpy_web_view_test_screen.dart';
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
