import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../network.dart';
import '../../../auth.dart';
import '../../../storage.dart';
import '../../../device.dart';

/// Ready-to-use Riverpod providers for common PrimeKit services.
///
/// Import and use directly in your Riverpod consumers:
/// ```dart
/// final isOnline = ref.watch(pkConnectivityProvider);
/// final isAuth = ref.watch(pkIsAuthenticatedProvider);
/// ```

/// Stream of connectivity status. True = online, false = offline.
final pkConnectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityMonitor.instance.isConnected;
});

/// Whether the current user is authenticated.
final pkIsAuthenticatedProvider = Provider<bool>((ref) {
  return SessionManager.instance.isAuthenticated;
});

/// The current app preferences instance.
final pkAppPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences.instance;
});

/// The secure prefs instance.
final pkSecurePrefsProvider = Provider<SecurePrefs>((ref) {
  return SecurePrefs.instance;
});

/// Current app version string (e.g. "1.2.3").
final pkAppVersionProvider = FutureProvider<String>((ref) async {
  final info = await AppVersion.info;
  return info.version;
});
