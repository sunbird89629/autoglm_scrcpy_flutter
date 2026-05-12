// Real-device end-to-end tests for inject_text MCP tool.
// These tests require a physical Android device connected via ADB and use a
// real ScrcpySessionImpl for end-to-end verification.
//
// Run manually:
//   dart test test/real_device_inject_text_test.dart --tags real-device

@Tags(['real-device'])
library;

import 'package:adb_tools/adb_tools.dart';
import 'package:logger_utils/app_logger.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:scrcpy_client/scrcpy_client.dart';
import 'package:scrcpy_mcp/src/scrcpy_mcp_adapters.dart';
import 'package:test/test.dart';

import 'real_device_test_utils.dart';

void main() {
  late ScrcpyMcpAdb adb;
  late List<String> realDevices;

  initLogging();

  setUpAll(() async {
    adb = ScrcpyMcpAdb(AdbClient());
    realDevices = await adb.getDevices();
  });

  group('inject_chinese_text', () {
    late ScrcpySessionImpl e2eSession;
    late RealDeviceE2eEnv e2eEnv;

    setUpAll(() async {
      e2eSession = await ScrcpySessionImpl.create(adb: adb);
      e2eEnv = RealDeviceE2eEnv(adb: adb, session: e2eSession);
      await e2eEnv.connect();
      await e2eEnv.client.callTool(CallToolRequest(
        name: 'start_mirroring',
        arguments: {'device_id': realDevices.first},
      ));
    });

    tearDownAll(() async {
      if (realDevices.isEmpty) return;
      try {
        await e2eEnv.client.callTool(
          const CallToolRequest(name: 'stop_mirroring'),
        );
      } catch (_) {
        // Transport may already be closed; ignore cleanup errors.
      }
    });

    test('inject_chinese_text_with_clipboard', () async {
      // 如果没有连接的设备，标记原因并跳过测试
      if (realDevices.isEmpty) {
        markTestSkipped('No Android device connected via ADB');
        return;
      }
      // 打开通讯录页面，这个页面有输入框，可以输入内容
      // ignore: unused_local_variable
      final processResult = await adb.shell(
        [
          'am',
          'start',
          '-a',
          'android.intent.action.INSERT',
          '-t',
          'vnd.android.cursor.dir/contact'
        ],
        deviceId: realDevices.first,
      );

      // TODO(test): Complete test implementation
    }, timeout: Timeout(Duration(seconds: 60)));
  });
}
