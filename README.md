# Summary
A simple Dependency Injection framework implementation based on `T.hashCode`. It is a simple port of the most basic functionalities of a .NET default dependency container.

Implemented:
- Service registration
- Service providing
- Singleton service handling
- Transient service handling
- Scoping (special case of singleton services with lifetime of a container or it's scoped copy)
- **Mostly** automatic cleaning after containers and their services

Not implemented:
- Unit tests [♟️]
- Source generation [👾]
- Circular reference prevention [😐]
- Keyed services [😐]
- Decorator based injection [💀]
- Automatic constructor invocation [💀]
- Automatic decorator based registration [💀]
- Multiple implementations of singular type [💀]

Legend:
- ♟️ - most likely to be implemented
- 😐 - will be implemented if the need rises
- 👾 - sounds fun but it's not likely to be fully implemented
- 💀 - not in the plan right now

<br>

**❗This project mostly serves as a way for me to learn and play around with Dart language and Flutter framework.❗**

**❗ While it does work and serves it's purpose relatively well, it was not tested properly and might contain bugs or performance issues. (especially with isolates)❗**

## Service registration 
Services can be added by chaining methods `ServiceContainerBuilder.add<T>(T Function(ServiceContainer) builder, lifetime: ServiceLifeTime.singleton)`. 

Lifetime can be one of: `[singleton, scoped, transient]`.
```dart
final container = new ServiceContainerBuilder()
    .add((container) => {
        final dependencyA = container.provide<DependencyA>();
        return DependencyB(dependencyA);
    })
    .add((_) => DependencyA(), lifetime: ServiceLifetime.Transient)
```
Factory functions are not invoked until a service is requested, so dependencies can be resolved in them without much care about registration order.

## Service providing
Services can be obtained by one of the following methods:

```dart
/// Can return null if not registered
ServiceType? nullableService = container.provide<ServiceType>();

/// Will throw exception of type [ServiceNotRegistered] if not registered
ServiceType service = container.provideRequired<ServiceType>();
```

## Automatic cleanup
Dependency Injection introduces easy access to any dependant object needed at the moment, but it also makes it much harder to trace the moment the same objects go out of scope.

For all services that requires cleanup after usage there is implemented a [Disposable pattern](https://en.wikipedia.org/wiki/Dispose_pattern) in form of:
```dart
abstract class Disposable{
    void dispose();
}
```
When registered service implements it, service container will perform automatic cleanup when method `dispose()` is called on it.

**While automatic cleanup is optional, it's ill advised to skip it in case any of a services requires cleanup.**

### Cleanup rules:
- Root provider will not cleanup any transient services by itself. It's up to programmer to clean them up.*
- Scoped containers only cleans their scoped services and transients created within their scope and will ignore their child scopes.
- Cleanup is not ordered and each `Disposable` should only clean their state without dependant services.

| * - Since root container can be a long lived object, leaving it to container would cause a lot of trash being piled up without any clearing by either container or garbage collector.

## Container sealing
While it is not required, it is adviced to seal container when all services are registered. Container that is not sealed is still open to new registrations or replacements during runtime resulting in unpredicted behaviour.
```dart
final serviceProvider = container.seal() // Also casts to ServiceContainer;
```
**❗Performing registrations on sealed container results in thrown Exception.❗**
## Scoping
Scope is an Unit of Work object that holds a copy of scoped service factories.

New scope of a container can be created by invoking `ServiceContainer.createScope()`.
```dart
class Counter {
    int _value = 0;
    int get value {
        return _value++;
    }
}

final container = new ServiceContainerBuilder()
    .add((_) => Counter(), lifetime: ServiceLifetime.scoped)
    .add((sp) => "Counter value is: ${sp.provide<Counter>().value}", lifetime: ServiceLifetime.transient)
    .seal();
final scopedContainer = container.createScope();

debugPrint(container.provide<String>());        // Counter value is: 0
debugPrint(container.provide<String>());        // Counter value is: 1
debugPrint(scopedContainer.provide<String>());  // Counter value is: 0
debugPrint(container.provide<String>());        // Counter value is: 2

```
Each scoped container holds a reference to the root container in case a singleton or transient service will be requested. Also new scoped containers can be created based on other scopes. Each container will only hold reference to the root so all previous containers when get out of scope, are going to be subjects of garbage collecting even if their children are still live objects.

**Scoped containers are sealed!**

While it is possible to create a scoped container from unsealed builder, replaced registrations are not reflected in scoped container if specified type was already provided at least once.

## Good practices
- Never work on root provider
- Never create a scope without sealing root container
- Don't dispose provided services by yourself
- Always dispose scopes after work on them is finished