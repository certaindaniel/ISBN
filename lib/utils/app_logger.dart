import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 小型日誌封裝：在 Debug 模式時使用 `debugPrint`（方便在 IDE 顯示），
/// 在 Release/非 debug 模式使用 `dart:developer.log` 發出結構化記錄。
class AppLogger {
  static const String _name = 'ISBNApp';

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    } else {
      developer.log(message, name: _name, level: 500);
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint(message);
    } else {
      developer.log(message, name: _name, level: 800);
    }
  }

  static void warn(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('WARN: $message');
      if (error != null) debugPrint('  error: $error');
      if (stackTrace != null) debugPrint('  stack: $stackTrace');
    } else {
      developer.log(message,
          name: _name, level: 900, error: error, stackTrace: stackTrace);
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint('  error: $error');
      if (stackTrace != null) debugPrint('  stack: $stackTrace');
    } else {
      developer.log(message,
          name: _name, level: 1000, error: error, stackTrace: stackTrace);
    }
  }
}
