import 'dart:developer' as developer;

/// Logs via dart:developer so it shows in DevTools; release builds drop `print`.
void logError(String message, [Object? error, StackTrace? stackTrace]) {
  developer.log(message, error: error, stackTrace: stackTrace, name: 'proving_tool', level: 1000);
}
