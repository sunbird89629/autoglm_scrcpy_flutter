import 'dart:io';
import 'package:autoglm_core/autoglm_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AppLogger', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('logger_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('maybeLog is a no-op when AppLogger is not initialized', () {
      // Should not throw
      appLogger.maybeLog('hello');
    });

    test('initAppLogger sets the global appLogger and isInitialized', () {
      initAppLogger(logsDir: tempDir.path);
      expect(AppLogger.isInitialized, isTrue);
      expect(appLogger, isA<AppLogger>());
    });

    test('writes a line to a dated log file under logsDir', () async {
      initAppLogger(logsDir: tempDir.path);
      appLogger.info('hello');
      await appLogger.flush();

      final logFile = File(p.join(tempDir.path, 'app.log'));
      expect(logFile.existsSync(), isTrue);
      expect(logFile.readAsStringSync(), contains('hello'));
    });
  });
}
