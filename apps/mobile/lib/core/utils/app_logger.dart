import 'package:logger/logger.dart';

/// A custom log printer that formats logs as: `[ClassName] Message`
class _AppLogPrinter extends LogPrinter {
  final String className;

  _AppLogPrinter(this.className);

  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final message = event.message;
    final error = event.error;

    final formattedMessage = '[HP][$className] $message';

    final lines = <String>[];

    if (color != null) {
      lines.add(color(formattedMessage));
    } else {
      lines.add(formattedMessage);
    }

    if (error != null) {
      final errorLines = error.toString().split('\n');
      lines.addAll(errorLines.map((e) => '[HP]$e'));
    }

    if (event.stackTrace != null) {
      final stackLines = event.stackTrace.toString().split('\n');
      lines.addAll(stackLines.map((e) => '[HP]$e'));
    }

    return lines;
  }
}

/// A wrapper around `logger` that provides easy structured logging.
///
/// Example usage:
/// ```dart
/// final _log = AppLogger('AuthService');
/// _log.info('Attempting to log in...');
/// ```
class AppLogger {
  final Logger _logger;

  AppLogger(String className)
    : _logger = Logger(printer: _AppLogPrinter(className), level: Level.all);

  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
