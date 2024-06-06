class GlobalContainerNotRegistered implements Exception {
  @override
  String toString() {
    return ("No global container registered. "
        "To use this functionality "
        "use registerGlobalContainer(container)");
  }
}
