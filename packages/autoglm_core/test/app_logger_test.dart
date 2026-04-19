import 'dart:io';

import 'package:autoglm_core/autoglm_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppLogger', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('logger_test_');
    });

    tearDown(() async {
      if (tmp.existsSync()) {
        await tmp.delete(recursive: true);
      }
    });

    test('maybeLog is a no-op when AppLogger is not initialized', () {
      // This test runs first so the static _instance is still null.
      // Once initAppLogger runs (in a later test) the static cannot be
      // reset within the same isolate, so test ordering matters here.
      // Contract: maybeLog never throws regardless of state.
      expect(() => AppLogger.maybeLog(() => 'msg'), returnsNormally);
    });

    test('writes a line to a dated log file under logsDir', () async {
      final logger = AppLogger(tmp)..i('hello');
      await logger.flush();

      final files = tmp
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('autoglm-'))
          .toList();
      expect(files, hasLength(1));
      final content = files.single.readAsStringSync();
      expect(content, contains('hello'));
    });

    test('initAppLogger sets the global appLogger and isInitialized', () {
      expect(AppLogger.isInitialized, isFalse);
      initAppLogger(tmp);
      expect(AppLogger.isInitialized, isTrue);
      expect(() => appLogger.i('after init'), returnsNormally);
    });
  });
}
