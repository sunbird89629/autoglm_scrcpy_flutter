import 'dart:convert';

import 'package:adb_tools/adb_tools.dart';
import 'package:logger_utils/logger_utils.dart';
import 'package:scrcpy_mcp/scrcpy_mcp.dart';
import 'package:test/test.dart';

String get _deviceId => '39111FDJH00D47';

void main() {
  const String taskContent = '帮我通过 chrome 打开 twitter 的官网';
  test('real phone agent model test', () async {
    initLogging();
    final adb = ScrcpyMcpAdb(AdbClient());

    final phoneAgent = PhoneAgent(
      config: const AgentConfig(maxSteps: 5),
      llmClient: OpenAiLlmClient.fromTest(),
      takeScreenshot: () async {
        final bytes = await adb.takeScreenshot(_deviceId);
        return (base64: base64Encode(bytes), mimeType: 'image/png');
      },
      actionRunner: (action) async => 'executed: $action',
    );
    final agentResult = await phoneAgent.run(taskContent);
    expect(agentResult, isNotNull);
  }, skip: false);
}
