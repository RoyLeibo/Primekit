# Contributing to Primekit

Thank you for your interest in contributing to Primekit! This document outlines the process
for contributing code, reporting bugs, and suggesting features.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Architecture Guide](#architecture-guide)
- [Submitting Changes](#submitting-changes)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Adding a New Module](#adding-a-new-module)

---

## Code of Conduct

Be respectful, inclusive, and constructive. We're here to build good software together.

---

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork: `git clone https://github.com/YOUR_USERNAME/Primekit.git`
3. **Set upstream**: `git remote add upstream https://github.com/RoyLeibo/Primekit.git`
4. **Create a branch**: `git checkout -b feat/my-feature`

---

## Development Setup

### Prerequisites

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`

### Install dependencies

```bash
cd Primekit
flutter pub get
```

### Run tests

```bash
flutter test
flutter test --coverage
```

### Format code

```bash
dart format lib test
```

### Analyze

```bash
dart analyze
```

### Run the example app

```bash
cd example
flutter pub get
flutter run
```

---

## Architecture Guide

### Module Structure

Every module lives in `lib/src/<module>/` and must have:

```
lib/src/my_module/
├── my_module.dart          ← barrel export
├── my_feature.dart         ← main class
└── my_models.dart          ← data classes
```

With a corresponding barrel in `lib/`:
```
lib/my_module.dart          ← re-exports lib/src/my_module/my_module.dart
```

### Key Patterns

**Result type for errors:**
```dart
// Always use Result<S, F>, never throw from public APIs
Future<PkResult<User>> fetchUser(String id) async {
  try {
    final data = await api.get('/users/$id');
    return Result.success(User.fromJson(data));
  } catch (e) {
    return Result.failure(NetworkException(message: e.toString()));
  }
}
```

**Immutable data classes:**
```dart
// Always immutable, always copyWith
final class UserProfile {
  const UserProfile({required this.name, required this.email});
  final String name;
  final String email;
  UserProfile copyWith({String? name, String? email}) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
  );
}
```

**Abstract providers for third-party integrations:**
```dart
// Never depend on a specific SDK — use an abstract provider
abstract class AnalyticsProvider {
  Future<void> logEvent(AnalyticsEvent event);
}
// Users implement their own or use bundled providers
```

---

## Submitting Changes

### Branch naming

- `feat/feature-name` — new feature
- `fix/bug-description` — bug fix
- `docs/what-changed` — documentation only
- `test/what-tested` — tests only
- `refactor/what-changed` — refactoring

### Commit messages (Conventional Commits)

```
feat(analytics): add FunnelTracker with step completion tracking
fix(auth): handle 401 during token refresh
docs(readme): add billing quick start example
test(forms): add email validation edge cases
```

### Pull Request checklist

- [ ] Tests added/updated (coverage ≥ 80%)
- [ ] Documentation updated
- [ ] `dart analyze` passes with no warnings
- [ ] `dart format` applied
- [ ] CHANGELOG.md entry added
- [ ] Example updated if public API changed
- [ ] No breaking changes (or clearly marked and versioned)

---

## Code Standards

### Dart style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- `final` everything that doesn't need to change
- `const` constructors wherever possible
- Prefer `sealed class` for discriminated unions
- Prefer `final class` for concrete, non-extensible types
- No `dynamic` in public APIs
- All public symbols must have dartdoc comments

### What we don't accept

- Console `print()` statements (use `PrimekitLogger`)
- Mutable state without justification
- `dynamic` parameters on public APIs
- Breaking changes without major version bump
- External dependencies without strong justification

---

## Testing Requirements

Every contribution must include tests. Minimum **80% line coverage** on changed files.

### Test structure

```
test/
└── analytics/
    ├── event_tracker_test.dart
    ├── funnel_tracker_test.dart
    └── analytics_event_test.dart
```

### Test format

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/analytics.dart';

class MockAnalyticsProvider extends Mock implements AnalyticsProvider {}

void main() {
  late EventTracker tracker;
  late MockAnalyticsProvider mockProvider;

  setUp(() {
    mockProvider = MockAnalyticsProvider();
    tracker = EventTracker.testInstance(providers: [mockProvider]);
  });

  group('EventTracker', () {
    test('fans out to all providers on logEvent', () async {
      when(() => mockProvider.logEvent(any())).thenAnswer((_) async {});

      await tracker.logEvent(AnalyticsEvent.screenView(screenName: 'Home'));

      verify(() => mockProvider.logEvent(any())).called(1);
    });
  });
}
```

---

## Adding a New Module

1. Create `lib/src/my_module/` directory
2. Create `lib/src/my_module/my_module.dart` barrel export
3. Create `lib/my_module.dart` top-level entry point
4. Add export to `lib/primekit.dart`
5. Create `test/my_module/` with tests
6. Add module to README.md module table
7. Add dartdoc to all public classes
8. Update CHANGELOG.md

---

## Questions?

Open a [GitHub Discussion](https://github.com/RoyLeibo/Primekit/discussions) or file an
[issue](https://github.com/RoyLeibo/Primekit/issues).
