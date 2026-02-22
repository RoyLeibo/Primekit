/// Primekit Crash module.
///
/// Error boundaries, structured crash reporting with breadcrumbs, and
/// pluggable backends (Firebase Crashlytics, Sentry).
///
/// ## Quick-start
///
/// ```dart
/// import 'package:primekit/crash.dart';
///
/// // 1. Initialise once at app startup
/// await CrashConfig.initialize(
///   MultiCrashReporter([
///     FirebaseCrashReporter(),
///     SentryCrashReporter(dsn: 'https://xxx@sentry.io/123'),
///   ]),
///   captureFlutterErrors: true,
///   capturePlatformErrors: true,
/// );
///
/// // 2. Add breadcrumbs
/// CrashConfig.addBreadcrumb(Breadcrumb(
///   message: 'User tapped checkout',
///   type: BreadcrumbType.userAction,
///   category: 'cart',
/// ));
///
/// // 3. Wrap risky widget subtrees
/// ErrorBoundary(
///   reporter: CrashConfig.reporter,
///   fallback: const Text('Oops'),
///   child: MyWidget(),
/// )
/// ```
library primekit_crash;

export 'crash_config.dart';
export 'crash_reporter.dart';
export 'error_boundary.dart';
export 'firebase_crash_reporter.dart';
export 'multi_crash_reporter.dart';
export 'sentry_crash_reporter.dart';
