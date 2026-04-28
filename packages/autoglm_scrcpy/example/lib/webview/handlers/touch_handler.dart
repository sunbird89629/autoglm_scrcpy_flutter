import 'package:autoglm_scrcpy/autoglm_scrcpy.dart';
import 'package:autoglm_scrcpy_example/webview/handlers/js_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TouchHandler extends JavaScriptHandler {
  final void Function(ScrcpyInjectTouchMessage) onTouch;
  TouchHandler({required this.onTouch});

  @override
  String get handlerName => "touchHandler";

  @override
  JavaScriptHandlerCallback get callback => _handleTouchArgs;

  void _handleTouchArgs(List<dynamic> args) {
    if (args.length < 9) return;

    final action = (args[0] as num).toInt();
    final pointerId = (args[1] as num).toInt();
    final cssX = (args[2] as num).toInt();
    final cssY = (args[3] as num).toInt();
    final cssW = (args[4] as num).toInt();
    final cssH = (args[5] as num).toInt();
    final internalW = (args[6] as num).toInt();
    final internalH = (args[7] as num).toInt();
    final pressure = (args[8] as num).toDouble();

    // Map CSS-space coordinates to canvas internal-resolution space.
    final int x, y, width, height;
    if (internalW > 0 && internalH > 0 && cssW > 0 && cssH > 0) {
      x = (cssX * internalW / cssW).round();
      y = (cssY * internalH / cssH).round();
      width = internalW;
      height = internalH;
    } else {
      // No video frame yet; use CSS coordinates directly.
      x = cssX;
      y = cssY;
      width = cssW;
      height = cssH;
    }

    onTouch(ScrcpyInjectTouchMessage(
      action: action,
      pointerId: pointerId,
      x: x,
      y: y,
      width: width,
      height: height,
      pressure: pressure,
    ));
  }
}
