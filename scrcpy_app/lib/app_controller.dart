import 'package:adb_tools/adb_tools.dart';
import 'package:flutter/material.dart';
import 'package:scrcpy_app/mcp_server_controller.dart';
import 'package:scrcpy_app/scrcpy_app_adb.dart';
import 'package:scrcpy_view/scrcpy_view.dart';

class ConsoleScrcpyLogger implements ScrcpyLogger {
  const ConsoleScrcpyLogger();
  @override
  void debug(String message) => print('DEBUG: $message');
  @override
  void info(String message) => print('INFO: $message');
  @override
  void warn(String message, [Object? error, StackTrace? stack]) =>
      print('WARN: $message $error');
  @override
  void error(String message, [Object? error, StackTrace? stack]) =>
      print('ERROR: $message $error');
}

class AppController extends ChangeNotifier {
  AppController._();
  static final _instance = AppController._();
  factory AppController() => _instance;

  final scrcpyViewController = ScrcpyViewController(
    adb: ScrcpyAppAdb(const AdbClientImpl()),
  );

  late final McpServerController mcpServerController = McpServerController(
    session: scrcpyViewController,
    adb: const ScrcpyAppAdb(AdbClientImpl()),
  );

  bool _running = false;
  bool get running => _running;
  set running(bool value) {
    _running = value;
    notifyListeners();
  }

  void injectKey(int keycode) {
    scrcpyViewController.injectKey(keycode);
  }

  Future<void> connectDevice(final String deviceId) async {
    await scrcpyViewController.start(deviceId, onStarted: () {
      running = true;
    });
  }
}
