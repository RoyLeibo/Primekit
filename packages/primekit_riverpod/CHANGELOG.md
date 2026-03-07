# Changelog

## [1.1.0] — 2026-03-07

### Version bump
- Sync version with primekit 1.1.0 (AI + Location modules added to primekit)


## [1.0.0] — 2026-03-07

Initial release of `primekit_riverpod`, extracted from the monolithic `primekit` package.

### Included
- **PkAsyncNotifierMixin**: Riverpod `AsyncNotifier` with `Result<T>` lifecycle
- **PkStreamNotifierMixin**: Stream-backed notifier mixin
- **PkPaginationState / PkPaginationNotifierMixin**: Cursor-based pagination
- **Built-in providers**: `pkConnectivityProvider`, `pkIsAuthenticatedProvider`, `pkAppPreferencesProvider`, `pkSecurePrefsProvider`, `pkAppVersionProvider`
