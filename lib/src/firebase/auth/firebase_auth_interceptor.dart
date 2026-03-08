import 'package:firebase_auth/firebase_auth.dart';
import 'package:primekit/auth.dart';

/// A ready-to-use [AuthInterceptor] for Firebase Auth apps.
///
/// Automatically injects Firebase ID tokens and refreshes them when expired.
///
/// ```dart
/// final client = PrimekitNetworkClient(
///   baseUrl: 'https://api.example.com',
///   interceptors: [FirebaseAuthInterceptor()],
/// );
/// ```
class FirebaseAuthInterceptor extends AuthInterceptor {
  FirebaseAuthInterceptor({
    TokenStore? tokenStore,
    void Function()? onSessionExpired,
  }) : super(
         tokenStore: tokenStore ?? TokenStore.instance,
         onRefresh: (_) async {
           final user = FirebaseAuth.instance.currentUser;
           if (user == null) return null;
           return user.getIdToken(true);
         },
         onSessionExpired: onSessionExpired ?? SessionManager.instance.logout,
       );

  /// Creates a [FirebaseAuthInterceptor] that populates the token store
  /// from the current Firebase user on initialisation.
  static Future<FirebaseAuthInterceptor> initialised({
    void Function()? onSessionExpired,
  }) async {
    final interceptor = FirebaseAuthInterceptor(
      onSessionExpired: onSessionExpired,
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        await TokenStore.instance.saveAccessToken(token);
      }
    }
    return interceptor;
  }
}
