import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'widget_data.dart';

/// Generic bridge between a Flutter app and its home screen widget.
///
/// Wraps the `home_widget` package to provide a uniform API for pushing data,
/// reading cached data, and handling widget tap callbacks.
///
/// ```dart
/// final service = PkHomeWidgetService(appGroupId: 'group.com.myapp.widget');
/// await service.initialize();
/// await service.updateWidget(
///   widgetName: PkWidgetName(ios: 'MyWidget', android: 'MyWidgetProvider'),
///   data: myWidgetData,
/// );
/// ```
class PkHomeWidgetService {
  /// Creates a [PkHomeWidgetService].
  ///
  /// [appGroupId] is required for iOS App Group sharing.
  PkHomeWidgetService({required this.appGroupId});

  /// The iOS App Group ID used for data sharing between app and widget.
  final String appGroupId;

  static const _tag = 'HomeWidget';

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Initializes the home_widget package with the configured [appGroupId].
  ///
  /// Call once in `main()` or on app foreground.
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
      PrimekitLogger.debug('Initialized with appGroupId: $appGroupId',
          tag: _tag);
    } catch (error) {
      throw HomeWidgetException(
        message: 'Failed to initialize home widget: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Push data
  // ---------------------------------------------------------------------------

  /// Pushes [data] to shared storage and triggers a widget refresh.
  ///
  /// Each entry in [PkWidgetData.toWidgetMap] is saved individually via
  /// `HomeWidget.saveWidgetData`. After saving, the widget identified by
  /// [widgetName] is told to reload.
  Future<void> updateWidget({
    required PkWidgetName widgetName,
    required PkWidgetData data,
  }) async {
    try {
      final map = data.toWidgetMap();
      for (final entry in map.entries) {
        await _saveEntry(entry.key, entry.value);
      }

      await HomeWidget.updateWidget(
        iOSName: widgetName.ios,
        androidName: widgetName.android,
      );
      PrimekitLogger.debug(
        'Updated widget (${map.length} keys)',
        tag: _tag,
      );
    } catch (error) {
      throw HomeWidgetException(
        message: 'Failed to update widget: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Read data
  // ---------------------------------------------------------------------------

  /// Reads a single value from widget shared storage.
  ///
  /// Returns `null` if no value is stored for [key].
  Future<T?> getWidgetValue<T>(String key) async {
    try {
      return await HomeWidget.getWidgetData<T>(key);
    } catch (error) {
      PrimekitLogger.warning(
        'Failed to read widget key "$key": $error',
        tag: _tag,
        error: error,
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Callbacks
  // ---------------------------------------------------------------------------

  /// Registers a [callback] that fires when the user taps the home widget.
  ///
  /// The [Uri] parameter contains the deep-link / action URI configured in
  /// the native widget definition.
  void registerCallback(Future<void> Function(Uri?) callback) {
    HomeWidget.widgetClicked.listen(callback);
    PrimekitLogger.debug('Widget tap callback registered', tag: _tag);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _saveEntry(String key, dynamic value) async {
    if (value is String) {
      await HomeWidget.saveWidgetData<String>(key, value);
    } else if (value is int) {
      await HomeWidget.saveWidgetData<int>(key, value);
    } else if (value is double) {
      await HomeWidget.saveWidgetData<double>(key, value);
    } else if (value is bool) {
      await HomeWidget.saveWidgetData<bool>(key, value);
    } else {
      await HomeWidget.saveWidgetData<String>(key, value.toString());
    }
  }
}

// ---------------------------------------------------------------------------
// Supporting types
// ---------------------------------------------------------------------------

/// Platform-specific widget identifiers.
///
/// [ios] corresponds to the WidgetKit widget name.
/// [android] corresponds to the `AppWidgetProvider` class name.
@immutable
class PkWidgetName {
  /// Creates a [PkWidgetName].
  const PkWidgetName({required this.ios, required this.android});

  /// iOS WidgetKit extension name, e.g. `'PawTrackWidget'`.
  final String ios;

  /// Android AppWidgetProvider class name, e.g. `'PawTrackWidgetProvider'`.
  final String android;
}

// HomeWidgetException is defined in core/exceptions.dart
