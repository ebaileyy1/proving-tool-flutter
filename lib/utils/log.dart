import 'dart:developer' as developer;

/// Routes error logging through `dart:developer` (visible in DevTools/IDE
/// debug console) instead of `print`, which production builds otherwise
/// swallow silently.
void logError(String message, [Object? error, StackTrace? stackTrace]) {
  developer.log(
    message,
    error: error,
    stackTrace: stackTrace,
    name: 'proving_tool',
    level: 1000,
  );
}
