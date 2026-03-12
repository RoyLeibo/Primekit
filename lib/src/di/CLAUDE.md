# di — Dependency Injection

**Purpose:** Service locator with lifecycle management. Foundational — no Primekit dependencies.

**Key exports:**
- `ServiceLocator` — global singleton registry (`ServiceLocator.instance`)
- `DiModule` — interface for grouping related registrations (implement per feature)
- `PkDisposable` — implement on services that need cleanup; called by `disposeAll()`
- `ServiceScope` — scoped DI for screens/features

**Registration patterns:**
```dart
locator.registerSingleton<T>(instance)
locator.registerLazySingleton<T>((_) => T())
locator.registerFactory<T>((_) => T())
locator.registerSingletonAsync<T>((_) async => await T.init())
await locator.allReady()   // wait for all async singletons
await locator.disposeAll() // call dispose() on all PkDisposable instances
```

**Maintenance:** Update when new lifetime type added or scope API changes.
