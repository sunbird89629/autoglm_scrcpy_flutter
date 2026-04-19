import 'dart:io';

import 'package:logger/logger.dart' as pkg;
import 'package:path/path.dart' as p;

/// Application-wide logger. Initialize once via [initAppLogger]; subsequent
/// access through the top-level [appLogger] singleton.
///
/// Writes to stdout AND a daily-rotated file under the `logsDir` passed at
/// construction time. Files are named `autoglm-YYYY-MM-DD.log`. Old files
/// are pruned to the most recent 5 by mtime.
class AppLogger {
  /// Creates an [AppLogger] that writes to [logsDir].
  AppLogger(Directory logsDir) : _logsDir = logsDir {
    if (!_logsDir.existsSync()) {
      _logsDir.createSync(recursive: true);
    }
    final today = DateTime.now();
    final fileName = 'autoglm-${_dateStamp(today)}.log';
    _file = File(p.join(_logsDir.path, fileName));
    _logger = pkg.Logger(
      printer: pkg.SimplePrinter(printTime: true, colors: false),
      output: pkg.MultiOutput([
        pkg.ConsoleOutput(),
        _FileOutput(_file),
      ]),
    );
    _pruneOldFiles();
  }

  final Directory _logsDir;
  late final File _file;
  late final pkg.Logger _logger;

  static AppLogger? _instance;

  /// Whether [initAppLogger] has been called in this isolate.
  static bool get isInitialized => _instance != null;

  /// Logs a debug-level message.
  void d(Object message) => _logger.d(message);

  /// Logs an info-level message.
  void i(Object message) => _logger.i(message);

  /// Logs a warning-level message.
  void w(Object message) => _logger.w(message);

  /// Logs an error-level message with optional [error] and [stack].
  void e(Object message, [Object? error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);

  /// Forces buffered output to disk. Tests should await this before reading
  /// the log file.
  Future<void> flush() async {
    await _logger.close();
  }

  /// No-op convenience used in modules where the logger may not yet be
  /// initialized (e.g. settings load during early boot).
  static void maybeLog(String Function() messageBuilder) {
    final inst = _instance;
    if (inst == null) return;
    try {
      inst.i(messageBuilder());
    } on Object {
      // Logging must never throw.
    }
  }

  void _pruneOldFiles() {
    final files = _logsDir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('autoglm-'))
        .toList()
      ..sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    for (final f in files.skip(5)) {
      try {
        f.deleteSync();
      } on Object {
        // best-effort pruning; failure here is non-critical
      }
    }
  }

  static String _dateStamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }
}

/// Initializes the global [appLogger]. Safe to call multiple times in the same
/// isolate — subsequent calls overwrite the singleton.
void initAppLogger(Directory logsDir) {
  AppLogger._instance = AppLogger(logsDir);
}

/// Top-level logger singleton. Throws a [StateError] if called before
/// [initAppLogger].
AppLogger get appLogger {
  final inst = AppLogger._instance;
  if (inst == null) {
    throw StateError(
      'appLogger accessed before initAppLogger() was called',
    );
  }
  return inst;
}

class _FileOutput extends pkg.LogOutput {
  _FileOutput(this._file);

  final File _file;

  @override
  void output(pkg.OutputEvent event) {
    final content = event.lines.map((l) => '$l\n').join();
    _file.writeAsStringSync(content, mode: FileMode.append);
  }
}
