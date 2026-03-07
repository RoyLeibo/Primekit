import 'package:flutter/foundation.dart';
import 'exceptions.dart';
import 'logger.dart';

/// Global Primekit configuration. Call [PrimekitConfig.initialize] once
/// in your `main()` before using any modules.
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await PrimekitConfig.initialize(
///     environment: PrimekitEnvironment.production,
///     analyticsProviders: [FirebaseAnalyticsProvider()],
///   );
///   runApp(const MyApp());
/// }
/// ```
class PrimekitConfig {
  PrimekitConfig._();

  static PrimekitConfig? _instance;

  /// The active configuration instance.
  static PrimekitConfig get instance {
    if (_instance == null) {
      throw const ConfigurationException(
        message:
            'PrimekitConfig not initialized. Call PrimekitConfig.initialize() '
            'in main() before using any Primekit modules.',
      );
    }
    return _instance!;
  }

  /// Returns `true` if Primekit has been initialized.
  static bool get isInitialized => _instance != null;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes Primekit with the given configuration.
  ///
  /// Must be called once before any module is used.
  static Future<void> initialize({
    PrimekitEnvironment environment = PrimekitEnvironment.production,
    PrimekitLogLevel logLevel = PrimekitLogLevel.warning,
    bool enableAnalytics = true,
    bool enableCrashReporting = true,
  }) async {
    if (_instance != null) {
      PrimekitLogger.warning(
        'PrimekitConfig.initialize() called more than once. Ignoring.',
      );
      return;
    }

    _instance = PrimekitConfig._()
      .._environment = environment
      .._logLevel = logLevel
      .._enableAnalytics = enableAnalytics
      .._enableCrashReporting = enableCrashReporting;

    PrimekitLogger.configure(logLevel);
    PrimekitLogger.info(
      'Primekit initialized — env: ${environment.name}, '
      'logLevel: ${logLevel.name}',
    );
  }

  /// Resets configuration (for testing only).
  @visibleForTesting
  static void reset() => _instance = null;

  // ---------------------------------------------------------------------------
  // Properties
  // ---------------------------------------------------------------------------

  late PrimekitEnvironment _environment;
  late PrimekitLogLevel _logLevel;
  late bool _enableAnalytics;
  late bool _enableCrashReporting;

  /// The current deployment environment.
  PrimekitEnvironment get environment => _environment;

  /// The active log level.
  PrimekitLogLevel get logLevel => _logLevel;

  /// Whether analytics tracking is enabled.
  bool get enableAnalytics => _enableAnalytics;

  /// Whether crash reporting is enabled.
  bool get enableCrashReporting => _enableCrashReporting;

  /// Whether running in debug mode.
  bool get isDebug => _environment == PrimekitEnvironment.debug || kDebugMode;

  /// Whether running in production.
  bool get isProduction => _environment == PrimekitEnvironment.production;
}

/// The deployment environment.
enum PrimekitEnvironment { debug, staging, production }

/// Controls how much Primekit logs.
enum PrimekitLogLevel { verbose, debug, info, warning, error, none }
