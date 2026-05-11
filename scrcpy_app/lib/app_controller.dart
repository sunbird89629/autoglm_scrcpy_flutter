import 'package:adb_tools/adb_tools.dart';
import 'package:flutter/material.dart';
import 'package:scrcpy_app/mcp_server_controller.dart';
import 'package:scrcpy_app/scrcpy_app_adb.dart';
import 'package:scrcpy_view/scrcpy_view.dart';

class AppController extends ChangeNotifier {
  AppController._();
  static final _instance = AppController._();
  factory AppController() => _instance;
  static const _adbClient = AdbClient();

  final scrcpyViewController = ScrcpyViewController(
    adb: ScrcpyAppAdb(_adbClient),
  );

  late final McpServerController mcpServerController = McpServerController(
    session: scrcpyViewController,
    adb: ScrcpyAppAdb(_adbClient),
  );

  bool _running = false;
  bool get running => _running;
  set running(bool value) {
    if (_running == value) return;
    _running = value;
    notifyListeners();
  }

  DeviceInfo? _deviceInfo;

  DeviceInfo? get deviceInfo => _deviceInfo;
  set deviceInfo(DeviceInfo? value) {
    if (_deviceInfo == value) return;
    _deviceInfo = value;
    notifyListeners();
  }

  void injectKey(int keycode) {
    scrcpyViewController.injectKey(keycode);
  }

  Future<void> connectDevice(final String serial) async {
    await scrcpyViewController.start(serial, onStarted: () async {
      running = true;
      deviceInfo = await _adbClient.getDeviceInfo(serial);
    });
  }
}
