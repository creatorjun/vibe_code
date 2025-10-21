class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class ApiException extends AppException {
  final int? statusCode;

  const ApiException(
      super.message, {
        this.statusCode,
        super.code,
        super.originalError,
      });
}

class TimeoutException extends AppException {
  const TimeoutException(super.message);
}

class FileException extends AppException {
  const FileException(super.message);
}

class FileSizeException extends FileException {
  const FileSizeException(super.message);
}

class FileTypeException extends FileException {
  const FileTypeException(super.message);
}
