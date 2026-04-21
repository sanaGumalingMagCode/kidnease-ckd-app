import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Logger utility for Kidnease application
/// Provides structured logging with Firebase Crashlytics integration
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  /// Log levels
  static const String _info = 'INFO';
  static const String _warning = 'WARNING';
  static const String _error = 'ERROR';

  /// Log an informational message
  void info(String message, {Map<String, dynamic>? context}) {
    _log(_info, message, context: context);
  }

  /// Log a warning message
  void warning(String message, {Map<String, dynamic>? context}) {
    _log(_warning, message, context: context);
  }

  /// Log an error message with optional error object and stack trace
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(_error, message, context: context);

    // Record error to Firebase Crashlytics
    if (error != null) {
      _recordError(message, error, stackTrace, context);
    }
  }

  /// Internal logging method
  void _log(String level, String message, {Map<String, dynamic>? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    final logMessage = '[$timestamp] [$level] $message$contextStr';

    if (kDebugMode) {
      // Print to console in debug mode
      debugPrint(logMessage);
    }
  }

  /// Record error to Firebase Crashlytics
  void _recordError(
    String message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  ) {
    try {
      // Add context information
      if (context != null) {
        for (final entry in context.entries) {
          // Skip sensitive data
          if (!_isSensitiveKey(entry.key)) {
            FirebaseCrashlytics.instance.setCustomKey(
              entry.key,
              entry.value.toString(),
            );
          }
        }
      }

      // Record the error
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        information: [
          'timestamp: ${DateTime.now().toIso8601String()}',
        ],
      );
    } catch (e) {
      // Fallback if Crashlytics fails
      if (kDebugMode) {
        debugPrint('Failed to record error to Crashlytics: $e');
      }
    }
  }

  /// Check if a key contains sensitive data
  bool _isSensitiveKey(String key) {
    final sensitiveKeys = [
      'email',
      'password',
      'token',
      'apikey',
      'secret',
      'auth',
      'credential',
    ];

    final lowerKey = key.toLowerCase();
    return sensitiveKeys.any((sensitive) => lowerKey.contains(sensitive));
  }

  /// Set user identifier for Crashlytics (use hashed or anonymized ID)
  void setUserId(String userId) {
    try {
      // Use hashed user ID to avoid logging PII
      final hashedId = userId.hashCode.toString();
      FirebaseCrashlytics.instance.setUserIdentifier(hashedId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to set user ID in Crashlytics: $e');
      }
    }
  }

  /// Clear user identifier
  void clearUserId() {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear user ID in Crashlytics: $e');
      }
    }
  }

  /// Log a custom event
  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    info('Event: $eventName', context: parameters);
  }
}

/// Global logger instance
final logger = Logger();
