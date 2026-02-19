/// Auth — JWT token storage, session management, OTP, and route protection.
///
/// Import this barrel to access the full Auth module:
/// ```dart
/// import 'package:primekit/src/auth/auth.dart';
/// ```
library primekit_auth;

export 'auth_interceptor.dart' show AuthInterceptor, TokenRefreshCallback;
export 'otp_service.dart' show OtpEntry, OtpService, OtpValidationResult;
export 'protected_route_guard.dart' show ProtectedRouteGuard;
export 'session_manager.dart'
    show
        SessionAuthenticated,
        SessionLoading,
        SessionManager,
        SessionState,
        SessionStateProvider,
        SessionUnauthenticated;
export 'token_store.dart' show TokenStore;
