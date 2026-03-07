# primekit_core

> Core building blocks for Flutter apps — validation schemas, async state, DI, result types, and extensions.

[![pub version](https://img.shields.io/pub/v/primekit_core.svg)](https://pub.dev/packages/primekit_core)
[![pub points](https://img.shields.io/pub/points/primekit_core)](https://pub.dev/packages/primekit_core)
[![license](https://img.shields.io/github/license/RoyLeibo/Primekit)](LICENSE)

Zero heavy dependencies — ships as a pure Flutter package.

## Installation

```yaml
dependencies:
  primekit_core: ^1.0.0
```

## What's included

- **Result types** — `Result<S, F>`, `PrimekitException` hierarchy
- **Async State** — `AsyncStateNotifier`, `AsyncBuilder`, `PaginatedStateNotifier`
- **Forms** — Zod-like schema validation: `PkSchema`, `ValidationResult`
- **DI** — `ServiceLocator`, `PkServiceScope`, module system
- **Extensions** — String, DateTime, List, Map utilities
- **Logger** — Structured `PrimekitLogger` with log levels

## Documentation

[github.com/RoyLeibo/Primekit](https://github.com/RoyLeibo/Primekit)

## License

MIT — see [LICENSE](LICENSE).
