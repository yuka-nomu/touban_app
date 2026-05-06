class RepositoryException implements Exception {
  const RepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'RepositoryException: $message';
    }
    return 'RepositoryException: $message ($cause)';
  }
}
