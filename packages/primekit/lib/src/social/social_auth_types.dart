import 'package:flutter/foundation.dart';

/// Supported OAuth social providers.
enum SocialProvider {
  /// Google sign-in via `google_sign_in`.
  google,

  /// Apple sign-in (requires `sign_in_with_apple` — stub if absent).
  apple,

  /// GitHub OAuth2 via Firebase Auth.
  github,

  /// Facebook Login (requires `flutter_facebook_auth` — stub if absent).
  facebook,
}

/// The result of a successful social sign-in.
@immutable
final class SocialAuthResult {
  /// Creates a [SocialAuthResult].
  const SocialAuthResult({
    required this.userId,
    required this.accessToken,
    required this.provider,
    this.email,
    this.displayName,
    this.avatarUrl,
  });

  /// Firebase UID.
  final String userId;

  /// Email address from the provider, if available.
  final String? email;

  /// Display name from the provider, if available.
  final String? displayName;

  /// Avatar / photo URL from the provider, if available.
  final String? avatarUrl;

  /// Provider access token.
  final String accessToken;

  /// Which provider was used.
  final SocialProvider provider;

  @override
  String toString() => 'SocialAuthResult(userId: $userId, provider: $provider)';
}

/// Abstract interface for social OAuth flows.
abstract interface class SocialAuthService {
  /// Signs in with the specified [provider].
  ///
  /// Returns `null` when the user cancels.
  Future<SocialAuthResult?> signIn(SocialProvider provider);

  /// Signs out from Firebase Auth and any provider-specific session.
  Future<void> signOut();

  /// Whether a user is currently signed in.
  bool get isSignedIn;

  /// The current user's Firebase UID, or `null` when signed out.
  String? get currentUserId;
}
