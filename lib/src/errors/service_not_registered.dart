class ServiceNotRegistered implements Exception {
  final Type requestedType;
  ServiceNotRegistered(this.requestedType);

  @override
  String toString() {
    return "Service of type ${requestedType.toString()} was not registed in service container";
  }
}
