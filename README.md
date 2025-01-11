# Summary
A simple Dependency Injection framework implementation based on `T.hashCode`. It is a simple port of the most basic functionalities of a .NET default dependency container.

Planned functionalities:
- [x] Service registration
- [x] Service providing
- [x] Singleton service handling
- [x] Transient service handling
- [x] Scoping (special case of singleton services with lifetime of a container or it's scoped copy)
- [x] Unit tests
- [x] **Mostly** automatic cleaning after containers and their services
- [x] Global injectors
- [ ] Registering services with functional destructors [♟️]
- [ ] Source generation [👾]
- [ ] Circular reference prevention [😐]
- [ ] Keyed services [😐]
- [ ] Decorator based injection [💀]
- [ ] Automatic constructor invocation [💀]
- [ ] Automatic decorator based registration [💀]
- [ ] Multiple implementations of singular type [💀]

Legend:
- ♟️ - most likely to be implemented
- 😐 - will be implemented if the need rises
- 👾 - sounds fun but it's not likely to be fully implemented
- 💀 - not in the plan right now

<br>

**❗This project mostly serves as a way for me to learn and play around with Dart language and Flutter framework.❗**

**❗ While it does work and serves it's purpose relatively well, it was tested on a surface level at best and might contain bugs or performance issues. (especially with isolates)❗**

## Creating a container 
Services can be added by chaining methods `ServiceContainerBuilder.add<T>(T Function(ServiceContainer) builder, lifetime: ServiceLifeTime.singleton)`. 

Lifetimes are described in table below:
| Lifetime  | Behaviour                                                      |
| --------- | -------------------------------------------------------------- |
| singleton | Single instance for entire lifetime of a container             |
| transient | Instance created on each injection                             |
| scoped    | Instance created on each scoped during first injection from it |

```dart
final builder = new ServiceContainerBuilder()
    .add((container) => {
        final dependencyA = container.provide<DependencyA>();
        return DependencyB(dependencyA);
    })
    .add((_) => DependencyA(), lifetime: ServiceLifetime.transient)
```
Factory functions are not invoked until a service is requested, so dependencies can be resolved in them without much care about registration order.

After finishing building call `build()` method to retrieve a container.

```dart
final ServiceContainer container = builder.build();
```

After building, the builder itself becomes `sealed` making it readonly. Any registration after sealing results in `ContainerSealed` exception.

## Service providing
Services can be obtained by one of the following methods:

```dart
/// Can return null if not registered
ServiceType? nullableService = container.provide<ServiceType>();

/// Will throw exception of type [ServiceNotRegistered] if not registered
ServiceType service = container.provideRequired<ServiceType>();
```

# Automatic cleanup
Dependency Injection introduces easy access to any dependant object needed at the moment, but it also makes it much harder to trace the moment the same objects go out of scope.

For all services that requires cleanup after usage there is implemented a [Disposable pattern](https://en.wikipedia.org/wiki/Dispose_pattern) in form of:
```dart
abstract class Disposable{
    void dispose();
}
```
When registered service implements it, service container will perform automatic cleanup when method `dispose()` is called on it.

**While automatic cleanup is optional, it's ill advised to skip it in case any of a services requires cleanup.**

## Cleanup rules:
- Root provider will not cleanup any transient services by itself. It's up to programmer to clean them up.*
- Scoped containers only cleans their scoped services and transients created within their scope and will ignore their child scopes.
- Cleanup is not ordered and each `Disposable` should only clean their state without dependant services.
- Implementation via extensions is not supported

| * - Since root container can be a long lived object, leaving it to container would cause a lot of trash being piled up without any clearing by either container or garbage collector.

## Quick dispose
In case a disposable or a scope are supposed to last only to the end of a function or specific part of code, there is an extension available, to help with cleanup:
```dart
final ResultType res = Dispose.of(service)
    .whileAlive(service => {
        //...
        return result;
    });
// or
final ResultType res = await Dispose.of(service)
    .whileAliveAsync(service async => {
        //...
        return await resultFuture;
    });
```
# Scoping
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

While it is possible to create a scoped container from manually created descriptor map, replaced registrations are not reflected in scoped container if specified type was already provided at least once.

# Global injection
This library allows for global injection if certain conditions are met:
- Build container was registered with function `registerGlobalContainer(ServiceContainer container)`
- Classes implement either `Scoped` or `Injected` mixins

## Global functional injection
To inject services into functions you can use following methods:

| Global injector function | Container equivalent     | Description                                                |
| ------------------------ | ------------------------ | ---------------------------------------------------------- |
| `T? inject<T>()`         | `T? provide<T>()`        | Provides an optional service                               |
| `T injectRequired<T>()`  | `T provideRequired<T>()` | Provides a required service (will throw if not registered) |

Those functions use currently used global scope, coming from either `registerGlobalContainer(ServiceContainer container)` or `Scoped.provideInScope()`. 

**❗While in functions it might be desired to use currently used scope, behaviour of global injectors in class instance methods might result in unpredictable behaviour!**

## Global class injection
Preferable way to inject services into classes is by using `Injected` mixin. It provides methods with the same signature as functional equivalents, but with consistent scope sampled from the time of class creation.

**To use those methods, prefixing them with `this` is necessary!**

```dart
class Example with Injected {
    late final DepA _dependency = this.injectRequired<DepA>();

    printFromField(){
        debugPrint(_dependency.message);
    }

    printFromInjection(){
        debugPrint(this.injectRequired<DepA>().message)
    }
}

class DepA {
    static int _sharedCounter = 0;
    int _counter;
    DepA(){
        _counter = _sharedCounter++;
    }
    
    get message(){
        return "Hello world $_counter";
    }
}

// ... Container creation

debugPrint(injectRequired<DepA>().message)  // Hello world 1

final instance = Example();
instance.printFromField()                  // Hello world 1
instance.printFromInjection()              // Hello world 1

registerGlobalContainer(getCurrentScope().createScope());

debugPrint(injectRequired<DepA>().message)  // Hello world 2
instance.printFromField()                  // Hello world 1
instance.printFromInjection()              // Hello world 1
```

## Global scoping
Scoping with global registration can be performed by either creating a scope manually from base container or by using `Scoped` mixin.

```dart
// Using standard flow
Dispose.of(getCurrentScope().createScope())
    .whileAlive(scope => {
        // ...
    });

// Using mixin flow
class A with Scoped {
    final DepA _dependencyA = provideInScope((scope) => scope.provideRequired<DepA>());
}
```

`provideInScope<T>(T Function(ServiceContainer))` makes sure that all dependant services are coming from the same scope
as the one constructed for class `A`. Similarly, when other `Scoped` classes are being constructed in nested scenario, `provideInScope()` will make sure to keep scopes consistent.

`Scoped` implements `Disposable` that will dispose of scope at the moment of calling `dispose()` on class itself.

# Usage notes
- Never work on root provider
- Don't dispose provided services by yourself
- Always dispose scopes after work on them is finished
- Actions resulting in unpredicted behaviours:
  - Using functional global injectors within class methods (if it's not `Injected`)
  - Using functional global injectors without `provideInScope()` in `Scoped` class
