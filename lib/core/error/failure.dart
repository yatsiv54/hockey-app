class Failure {
  const Failure({this.message = 'Unknown error', this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'Failure(message: ' + message + ', cause: ' + (cause?.toString() ?? 'null') + ')';
}

