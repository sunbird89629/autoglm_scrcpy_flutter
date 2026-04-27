import 'dart:async';
import 'dart:typed_data';

import 'package:autoglm_adb/autoglm_adb.dart';
import 'package:autoglm_core/autoglm_core.dart';
import 'package:autoglm_scrcpy/autoglm_scrcpy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(initAppLogger);

  test('sendControlMessage writes correct binary to injected sink', () async {
    final captured = <List<int>>[];
    final controller = StreamController<List<int>>(sync: true);
    controller.stream.listen(captured.add);

    final server = ScrcpyServer(
      adbClient: const AdbClient(),
      deviceId: 'test-device',
      controlSink: controller.sink,
    );

    server.sendControlMessage(
      const ScrcpyInjectTouchMessage(
        action: ScrcpyAction.down,
        pointerId: 1,
        x: 100,
        y: 200,
        width: 1080,
        height: 1920,
      ),
    );

    expect(captured.length, 1);
    final bytes = captured.single;
    expect(bytes.length, 32);
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    expect(bd.getUint8(0), 2); // type = inject touch
    expect(bd.getUint8(1), ScrcpyAction.down);

    await controller.close();
  });
}
