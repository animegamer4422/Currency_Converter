class ErrorException implements Exception {
  final String message;

  ErrorException(this.message);

  @override
  String toString() => message;
}

class ServerException extends ErrorException {
  ServerException([super.message = 'Server error occurred.']);
}

class CacheException extends ErrorException {
  CacheException([super.message = 'Cache error occurred.']);
}

class UnsupportedCurrencyException extends ErrorException {
  UnsupportedCurrencyException([
    super.message = 'Historical data is not available for this currency.',
  ]);
}
