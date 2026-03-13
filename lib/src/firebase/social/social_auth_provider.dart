import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../social.dart';

/// [SocialAuthService] backed by Firebase Auth.
///
/// Supports Google (web + mobile) and GitHub natively.
/// Apple and Facebook require additional packages and will throw a clear
/// [UnsupportedError] when called without them.
///
/// For Google sign-in with additional OAuth scopes (e.g. Google Calendar):
/// ```dart
/// final user = await FirebaseSocialAuth().signInWithGoogle(
///   additionalScopes: [
///     'https://www.googleapis.com/auth/calendar.events',
///   ],
/// );
/// ```
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
  // signIn (SocialAuthService interface)
  // ---------------------------------------------------------------------------

  @override
  Future<SocialAuthResult?> signIn(SocialProvider provider) async {
    switch (provider) {
      case SocialProvider.google:
        return _googleSignInToResult();
      case SocialProvider.apple:
        return _signInWithApple();
      case SocialProvider.github:
        return _signInWithGithub();
      case SocialProvider.facebook:
        return _signInWithFacebook();
    }
  }

  // ---------------------------------------------------------------------------
  // signInWithGoogle — convenience method that returns User? directly
  // ---------------------------------------------------------------------------

  /// Signs in with Google and returns the Firebase [User], or `null` if the
  /// user cancelled.
  ///
  /// On **web** uses [FirebaseAuth.signInWithPopup] to avoid deprecated
  /// google_sign_in web APIs. On **mobile** uses the google_sign_in 7.x
  /// singleton API.
  ///
  /// Pass [additionalScopes] to request extra OAuth scopes at sign-in time
  /// (e.g. Google Calendar scopes). The base `email` and `profile` scopes
  /// are always included.
  Future<User?> signInWithGoogle({
    List<String> additionalScopes = const [],
  }) async {
    final result = await _googleSignIn(additionalScopes: additionalScopes);
    return result;
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
        if (!kIsWeb) await GoogleSignIn.instance.signOut();
      } on Exception {
        // Ignore if Google Sign-In not configured.
      }
    } catch (error) {
      throw Exception('FirebaseSocialAuth.signOut failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Google — shared implementation
  // ---------------------------------------------------------------------------

  /// Core Google sign-in. Returns the Firebase [User] or null if cancelled.
  Future<User?> _googleSignIn({
    List<String> additionalScopes = const [],
  }) async {
    try {
      if (kIsWeb) {
        // Web: Firebase Auth popup (avoids deprecated google_sign_in web APIs)
        final result = await _auth.signInWithPopup(GoogleAuthProvider());
        return result.user;
      }

      // Mobile: google_sign_in 7.x singleton API
      final scopes = ['email', 'profile', ...additionalScopes];
      final GoogleSignInAccount googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate(
          scopeHint: scopes,
        );
      } catch (_) {
        return null; // User cancelled
      }

      final googleAuth = googleUser.authentication; // synchronous in 7.x
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes(scopes);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization?.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user;
    } catch (error) {
      throw Exception('Google sign-in failed: $error');
    }
  }

  /// Wraps [_googleSignIn] into a [SocialAuthResult] for the interface.
  Future<SocialAuthResult?> _googleSignInToResult() async {
    final user = await _googleSignIn();
    if (user == null) return null;
    return SocialAuthResult(
      userId: user.uid,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      accessToken: '',
      provider: SocialProvider.google,
    );
  }

  // ---------------------------------------------------------------------------
  // Apple  (stub — requires sign_in_with_apple package)
  // ---------------------------------------------------------------------------

  Future<SocialAuthResult?> _signInWithApple() async {
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
    throw UnsupportedError(
      'Facebook sign-in is not enabled. '
      'Add the `flutter_facebook_auth` package and implement '
      'FirebaseSocialAuth._signInWithFacebook().',
    );
  }
}
