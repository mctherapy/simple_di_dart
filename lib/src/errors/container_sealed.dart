class ContainerSealed implements Exception {
  @override
  String toString() {
    return "Current container is sealed and not open for new registrations";
  }
}
