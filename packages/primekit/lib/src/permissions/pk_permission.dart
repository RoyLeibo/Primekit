/// Primekit-owned permission types, independent of any platform SDK.
///
/// Use these types throughout your app to avoid direct coupling to
/// `permission_handler` or any other platform-specific permission library.
library;

// ---------------------------------------------------------------------------
// PkPermission
// ---------------------------------------------------------------------------

/// Platform-agnostic permission identifiers.
enum PkPermission {
  /// Camera hardware access.
  camera,

  /// Microphone hardware access.
  microphone,

  /// Fine (GPS-level) location while the app is in the foreground.
  location,

  /// Fine location access in the background ("always" mode).
  locationAlways,

  /// Push / local notification delivery.
  notifications,

  /// External storage read / write access (Android only; iOS has no direct
  /// equivalent).
  storage,

  /// Access to the device contacts database.
  contacts,

  /// Access to the device calendar.
  calendar,

  /// Bluetooth Classic and BLE scan / connect.
  bluetooth,

  /// Phone state and call access (Android only).
  phone,

  /// Photo library / media library access.
  photos,

  /// Sensor data (motion & fitness sensors, body sensors).
  sensors,
}

// ---------------------------------------------------------------------------
// PkPermissionStatus
// ---------------------------------------------------------------------------

/// Platform-agnostic permission status values.
enum PkPermissionStatus {
  /// The user has granted the permission.
  granted,

  /// The user has denied the permission but it can be requested again.
  denied,

  /// The user has permanently denied the permission. The app must direct
  /// the user to system settings to re-enable it.
  permanentlyDenied,

  /// The permission is restricted by device policy (iOS / macOS managed
  /// devices). It cannot be granted by the user.
  restricted,

  /// Only a portion of the requested access was granted (e.g. iOS
  /// limited photo library access).
  limited,

  /// The permission has not been requested yet (iOS first-time status).
  notDetermined,
}
