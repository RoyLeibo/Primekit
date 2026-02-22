import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart';

// ---------------------------------------------------------------------------
// Abstract data source
// ---------------------------------------------------------------------------

/// Abstract backend for user profile persistence.
abstract interface class ProfileDataSource {
  /// Fetches the raw profile map for [userId], or `null` if not found.
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// Persists [data] for [userId] (merge-update semantics).
  Future<void> updateProfile(String userId, Map<String, dynamic> data);

  /// Returns a stream that emits the raw profile map whenever it changes.
  Stream<Map<String, dynamic>?> watchProfile(String userId);
}

// ---------------------------------------------------------------------------
// ProfileService
// ---------------------------------------------------------------------------

/// Singleton service for reading and updating [UserProfile]s.
///
/// Configure once before use:
/// ```dart
/// ProfileService.instance.configure(source: FirebaseProfileSource());
///
/// final profile = await ProfileService.instance.getProfile('user_123');
/// await ProfileService.instance.updateAvatar(
///   userId: 'user_123',
///   avatarUrl: 'https://cdn.example.com/avatars/user_123.jpg',
/// );
/// ```
class ProfileService {
  ProfileService._();

  static final ProfileService _instance = ProfileService._();

  /// The global singleton instance.
  static ProfileService get instance => _instance;

  ProfileDataSource? _source;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// The data source used by this service.
  ///
  /// Must be set before calling any other method.
  set source(ProfileDataSource value) => _source = value;

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Returns the [UserProfile] for [userId], or `null` if not found.
  Future<UserProfile?> getProfile(String userId) async {
    _assertConfigured();
    try {
      final data = await _source!.fetchProfile(userId);
      if (data == null) return null;
      return UserProfile.fromJson(_normaliseId(userId, data));
    } catch (error) {
      throw Exception(
        'ProfileService.getProfile failed for "$userId": $error',
      );
    }
  }

  /// Applies [updates] to the profile for [userId] and returns the result.
  ///
  /// [updates] — map of fields to change (merge semantics).
  Future<UserProfile> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    _assertConfigured();
    try {
      await _source!.updateProfile(userId, updates);
      final data = await _source!.fetchProfile(userId);
      if (data == null) {
        throw Exception('Profile not found after update for "$userId"');
      }
      return UserProfile.fromJson(_normaliseId(userId, data));
    } catch (error) {
      throw Exception(
        'ProfileService.updateProfile failed for "$userId": $error',
      );
    }
  }

  /// Updates only the [avatarUrl] for [userId].
  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    _assertConfigured();
    try {
      await _source!.updateProfile(userId, {'avatarUrl': avatarUrl});
    } catch (error) {
      throw Exception(
        'ProfileService.updateAvatar failed for "$userId": $error',
      );
    }
  }

  /// Returns a stream that emits the [UserProfile] whenever it changes.
  ///
  /// Emits `null` when the profile is deleted.
  Stream<UserProfile?> watchProfile(String userId) {
    _assertConfigured();
    return _source!
        .watchProfile(userId)
        .map(
          (data) => data == null
              ? null
              : UserProfile.fromJson(_normaliseId(userId, data)),
        );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _assertConfigured() {
    assert(
      _source != null,
      'Call ProfileService.instance.configure() before use',
    );
  }

  /// Ensures the `id` field is present (Firestore docs use doc.id,
  /// not a field).
  static Map<String, dynamic> _normaliseId(
    String userId,
    Map<String, dynamic> data,
  ) =>
      {'id': userId, ...data};
}

// ---------------------------------------------------------------------------
// Firebase implementation
// ---------------------------------------------------------------------------

/// `ProfileDataSource` backed by Cloud Firestore.
///
/// User documents are stored in a Firestore `collection` with the user's
/// UID as the document ID.
final class FirebaseProfileSource implements ProfileDataSource {
  /// Creates a [FirebaseProfileSource].
  ///
  /// [firestore] defaults to [FirebaseFirestore.instance].
  FirebaseProfileSource({
    FirebaseFirestore? firestore,
    String collection = 'users',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collection = collection;

  final FirebaseFirestore _firestore;
  final String _collection;

  DocumentReference<Map<String, dynamic>> _docRef(String userId) =>
      _firestore.collection(_collection).doc(userId);

  // ---------------------------------------------------------------------------
  // fetchProfile
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final snap = await _docRef(userId).get();
      return snap.exists ? snap.data() : null;
    } catch (error) {
      throw Exception(
        'FirebaseProfileSource.fetchProfile failed for "$userId": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _docRef(userId).set(data, SetOptions(merge: true));
    } catch (error) {
      throw Exception(
        'FirebaseProfileSource.updateProfile failed for "$userId": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // watchProfile
  // ---------------------------------------------------------------------------

  @override
  Stream<Map<String, dynamic>?> watchProfile(String userId) =>
      _docRef(userId).snapshots().map((s) => s.exists ? s.data() : null);
}
