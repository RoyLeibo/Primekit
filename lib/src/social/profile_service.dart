import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_service_base.dart';

export 'profile_service_base.dart';

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
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _collection = collection;

  final FirebaseFirestore _firestore;
  final String _collection;

  DocumentReference<Map<String, dynamic>> _docRef(String userId) =>
      _firestore.collection(_collection).doc(userId);

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

  @override
  Stream<Map<String, dynamic>?> watchProfile(String userId) =>
      _docRef(userId).snapshots().map((s) => s.exists ? s.data() : null);
}
