/// Base failure class for error propagation across layers
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message && other.code == code;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() => 'Failure: $message${code != null ? ' (code: $code)' : ''}';
}

/// Authentication failure
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, {super.code});
}

/// Network failure
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// API failure
class ApiFailure extends Failure {
  final int? statusCode;

  const ApiFailure(super.message, {this.statusCode, super.code});

  @override
  String toString() => 'ApiFailure: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Storage failure
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

/// Camera failure
class CameraFailure extends Failure {
  const CameraFailure(super.message, {super.code});
}

/// Server failure
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Cache failure
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}
