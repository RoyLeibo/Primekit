import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

/// [SocialAuthService] backed by Firebase Auth.
///
/// Supports Google and GitHub out of the box. Apple and Facebook require
/// additional packages and will throw a clear [UnsupportedError] when called
/// without them.
final class FirebaseSocialAuth implements SocialAuthService {
  /// Creates a [FirebaseSocialAuth].
  ///
  /// [auth] defaults to [FirebaseAuth.instance].
  FirebaseSocialAuth({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // signIn
  // ---------------------------------------------------------------------------

  @override
  Future<SocialAuthResult?> signIn(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return _signInWithGoogle();
      case SocialProvider.apple:
        return _signInWithApple();
      case SocialProvider.github:
        return _signInWithGithub();
      case SocialProvider.facebook:
        return _signInWithFacebook();
    }
  }

  // ---------------------------------------------------------------------------
  // signOut
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Best-effort sign-out from Google (no-op if not used).
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // Ignore if Google Sign-In not configured.
      }
    } catch (error) {
      throw Exception('FirebaseSocialAuth.signOut failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult?> _signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return null;

      return SocialAuthResult(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
        accessToken: googleAuth.idToken ?? '',
        provider: SocialProvider.google,
      );
    } catch (error) {
      throw Exception('Google sign-in failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Apple  (stub — requires sign_in_with_apple package)
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult?> _signInWithApple() async {
    // Apple sign-in requires the `sign_in_with_apple` package.
    // Add it to pubspec.yaml:
    //   sign_in_with_apple: ^6.0.0
    // Then replace this body with the real implementation.
    throw UnsupportedError(
      'Apple sign-in is not enabled. '
      'Add the `sign_in_with_apple` package and implement '
      'FirebaseSocialAuth._signInWithApple().',
    );
  }

  // ---------------------------------------------------------------------------
  // GitHub
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult?> _signInWithGithub() async {
    try {
      final provider = GithubAuthProvider();
      final userCred = await _auth.signInWithProvider(provider);
      final user = userCred.user;
      if (user == null) return null;

      final token = userCred.credential?.accessToken ?? '';
      return SocialAuthResult(
        userId: user.uid,
        email: user.email,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
        accessToken: token,
        provider: SocialProvider.github,
      );
    } catch (error) {
      throw Exception('GitHub sign-in failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Facebook  (stub — requires flutter_facebook_auth package)
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult?> _signInWithFacebook() async {
    // Facebook sign-in requires the `flutter_facebook_auth` package.
    // Add it to pubspec.yaml:
    //   flutter_facebook_auth: ^7.0.0
    // Then replace this body with the real implementation.
    throw UnsupportedError(
      'Facebook sign-in is not enabled. '
      'Add the `flutter_facebook_auth` package and implement '
      'FirebaseSocialAuth._signInWithFacebook().',
    );
  }
}
