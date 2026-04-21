/// Base exception class for Kidnease application
abstract class KidneaseException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const KidneaseException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'KidneaseException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Authentication-related exceptions
class AuthenticationException extends KidneaseException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
  });

  factory AuthenticationException.weakPassword() {
    return const AuthenticationException(
      'Password must be at least 6 characters long',
      code: 'weak-password',
    );
  }

  factory AuthenticationException.emailAlreadyInUse() {
    return const AuthenticationException(
      'An account already exists with this email',
      code: 'email-already-in-use',
    );
  }

  factory AuthenticationException.userNotFound() {
    return const AuthenticationException(
      'No account found with this email',
      code: 'user-not-found',
    );
  }

  factory AuthenticationException.wrongPassword() {
    return const AuthenticationException(
      'Incorrect password',
      code: 'wrong-password',
    );
  }

  factory AuthenticationException.networkRequestFailed() {
    return const AuthenticationException(
      'No internet connection. Please check your network.',
      code: 'network-request-failed',
    );
  }

  factory AuthenticationException.fromFirebaseCode(String code) {
    switch (code) {
      case 'weak-password':
        return AuthenticationException.weakPassword();
      case 'email-already-in-use':
        return AuthenticationException.emailAlreadyInUse();
      case 'user-not-found':
        return AuthenticationException.userNotFound();
      case 'wrong-password':
        return AuthenticationException.wrongPassword();
      case 'network-request-failed':
        return AuthenticationException.networkRequestFailed();
      default:
        return AuthenticationException('Authentication failed: $code', code: code);
    }
  }

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Network-related exceptions
class NetworkException extends KidneaseException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });

  factory NetworkException.noConnection() {
    return const NetworkException(
      'No internet connection available',
      code: 'no-connection',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      'Request timed out. Please try again.',
      code: 'timeout',
    );
  }

  factory NetworkException.serverError() {
    return const NetworkException(
      'Server error occurred. Please try again later.',
      code: 'server-error',
    );
  }

  @override
  String toString() => 'NetworkException: $message';
}

/// API-related exceptions
class ApiException extends KidneaseException {
  final int? statusCode;

  const ApiException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  factory ApiException.rateLimitExceeded() {
    return const ApiException(
      'Rate limit exceeded. Please try again later.',
      statusCode: 429,
      code: 'rate-limit-exceeded',
    );
  }

  factory ApiException.invalidRequest() {
    return const ApiException(
      'Invalid request format',
      statusCode: 400,
      code: 'invalid-request',
    );
  }

  factory ApiException.unauthorized() {
    return const ApiException(
      'Unauthorized access',
      statusCode: 401,
      code: 'unauthorized',
    );
  }

  factory ApiException.serverError() {
    return const ApiException(
      'API service temporarily unavailable',
      statusCode: 500,
      code: 'server-error',
    );
  }

  factory ApiException.invalidResponse(String details) {
    return ApiException(
      'Invalid API response: $details',
      code: 'invalid-response',
    );
  }

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Validation-related exceptions
class ValidationException extends KidneaseException {
  final List<String>? missingFields;

  const ValidationException(
    super.message, {
    this.missingFields,
    super.code,
    super.originalError,
  });

  factory ValidationException.missingFields(List<String> fields) {
    return ValidationException(
      'Missing required fields: ${fields.join(', ')}',
      missingFields: fields,
      code: 'missing-fields',
    );
  }

  factory ValidationException.invalidValue(String field, String reason) {
    return ValidationException(
      'Invalid value for $field: $reason',
      code: 'invalid-value',
    );
  }

  factory ValidationException.outOfRange(String field, double min, double max) {
    return ValidationException(
      '$field must be between $min and $max',
      code: 'out-of-range',
    );
  }

  @override
  String toString() => 'ValidationException: $message';
}

/// Storage-related exceptions
class StorageException extends KidneaseException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
  });

  factory StorageException.quotaExceeded() {
    return const StorageException(
      'Storage limit reached. Please contact support.',
      code: 'quota-exceeded',
    );
  }

  factory StorageException.uploadFailed() {
    return const StorageException(
      'Upload failed. Please try again.',
      code: 'upload-failed',
    );
  }

  factory StorageException.permissionDenied() {
    return const StorageException(
      'Permission denied. Please sign in again.',
      code: 'permission-denied',
    );
  }

  factory StorageException.fileNotFound() {
    return const StorageException(
      'File not found',
      code: 'file-not-found',
    );
  }

  @override
  String toString() => 'StorageException: $message';
}

/// Camera/Image capture exceptions
class CameraException extends KidneaseException {
  const CameraException(
    super.message, {
    super.code,
    super.originalError,
  });

  factory CameraException.accessDenied() {
    return const CameraException(
      'Camera permission required. Please enable in settings.',
      code: 'camera_access_denied',
    );
  }

  factory CameraException.notAvailable() {
    return const CameraException(
      'Camera not available on this device',
      code: 'camera_not_available',
    );
  }

  factory CameraException.captureFailed() {
    return const CameraException(
      'Failed to capture image. Please try again.',
      code: 'capture_failed',
    );
  }

  @override
  String toString() => 'CameraException: $message';
}

/// JSON parsing exceptions
class JsonParseException extends KidneaseException {
  const JsonParseException(
    super.message, {
    super.code,
    super.originalError,
  });

  factory JsonParseException.invalidFormat() {
    return const JsonParseException(
      'Invalid JSON format',
      code: 'invalid-format',
    );
  }

  @override
  String toString() => 'JsonParseException: $message';
}
