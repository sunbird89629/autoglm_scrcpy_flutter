import 'package:autoglm_scrcpy_example/webview/harness_controller.dart';
import 'package:flutter/material.dart';

class WebViewHarnessScope extends InheritedNotifier<WebViewHarnessController> {
  const WebViewHarnessScope({
    super.key,
    required WebViewHarnessController controller,
    required super.child,
  }) : super(notifier: controller);

  static WebViewHarnessController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WebViewHarnessScope>();
    assert(
        scope != null, 'WebViewHarnessScope.of() called without an ancestor');
    return scope!.notifier!;
  }
}
