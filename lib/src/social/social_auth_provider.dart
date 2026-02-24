import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'social_auth_types.dart';

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
