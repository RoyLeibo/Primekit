# Changelog

## [1.1.0] — 2026-03-07

### Version bump
- Sync version with primekit 1.1.0 (AI + Location modules added to primekit)


## [1.0.0] — 2026-03-07

Initial release of `primekit_core`, extracted from the monolithic `primekit` package.

### Included modules
- **core**: `Result<T>`, `PrimekitException`, `PrimekitConfig`, `PrimekitLogger`, and extensions for `String`, `List`, `Map`, and `DateTime`
- **forms**: `PkSchema` validation engine — string, number, bool, date, list, object schemas with `.refine()` cross-field validation
- **async_state**: `AsyncStateNotifier`, `AsyncStateValue`, `PaginatedState`, `AsyncBuilder` widget
- **di**: `ServiceLocator`, `ServiceScope`, `PkServiceScopeWidget`, `Module`
