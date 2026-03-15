import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';
import 'sharing_models.dart';

/// Firestore sharing mixin for repository classes.
///
/// Provides standard `addMember`, `removeMember`, `getMemberRole`, and
/// `getMembers` operations that manipulate a `memberIds` array and a
/// `roles` map on any Firestore document.
///
/// ```dart
/// class PetRepository with PkSharingMixin {
///   @override
///   FirebaseFirestore get firestore => FirebaseFirestore.instance;
///
///   @override
///   PkSharingConfig get sharingConfig => const PkSharingConfig();
///
///   Future<void> sharePet(String petId, String userId) async {
///     await addMember('pets/$petId', userId, 'editor');
///   }
/// }
/// ```
mixin PkSharingMixin {
  static const _tag = 'Sharing';

  /// The Firestore instance used for sharing operations.
  FirebaseFirestore get firestore;

  /// Configuration for field names. Override to customize.
  PkSharingConfig get sharingConfig => const PkSharingConfig();

  // ---------------------------------------------------------------------------
  // Add member
  // ---------------------------------------------------------------------------

  /// Adds [userId] with [role] to the document at [docPath].
  ///
  /// Uses Firestore `arrayUnion` for the member IDs array and sets the role
  /// in the roles map. Also updates the `updatedAt` timestamp.
  Future<void> addMember(String docPath, String userId, String role) async {
    try {
      final docRef = firestore.doc(docPath);
      final config = sharingConfig;

      await docRef.update({
        config.memberIdsField: FieldValue.arrayUnion([userId]),
        '${config.rolesField}.$userId': role,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      PrimekitLogger.debug(
        'Added member $userId as $role to $docPath',
        tag: _tag,
      );
    } catch (error) {
      throw SharingException(
        message: 'Failed to add member $userId to $docPath: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Remove member
  // ---------------------------------------------------------------------------

  /// Removes [userId] from the document at [docPath].
  ///
  /// Uses Firestore `arrayRemove` for the member IDs array and deletes the
  /// role entry from the roles map.
  Future<void> removeMember(String docPath, String userId) async {
    try {
      final docRef = firestore.doc(docPath);
      final config = sharingConfig;

      await docRef.update({
        config.memberIdsField: FieldValue.arrayRemove([userId]),
        '${config.rolesField}.$userId': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      PrimekitLogger.debug(
        'Removed member $userId from $docPath',
        tag: _tag,
      );
    } catch (error) {
      throw SharingException(
        message: 'Failed to remove member $userId from $docPath: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Update role
  // ---------------------------------------------------------------------------

  /// Updates the role of [userId] on the document at [docPath].
  Future<void> updateMemberRole(
    String docPath,
    String userId,
    String role,
  ) async {
    try {
      final docRef = firestore.doc(docPath);
      final config = sharingConfig;

      await docRef.update({
        '${config.rolesField}.$userId': role,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      PrimekitLogger.debug(
        'Updated member $userId role to $role on $docPath',
        tag: _tag,
      );
    } catch (error) {
      throw SharingException(
        message: 'Failed to update member role: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  /// Returns the role of [userId] on the document at [docPath], or `null`
  /// if the user is not a member.
  Future<String?> getMemberRole(String docPath, String userId) async {
    try {
      final snapshot = await firestore.doc(docPath).get();
      if (!snapshot.exists) return null;

      final data = snapshot.data();
      if (data == null) return null;

      final roles = data[sharingConfig.rolesField];
      if (roles is! Map<String, dynamic>) return null;

      return roles[userId] as String?;
    } catch (error) {
      throw SharingException(
        message: 'Failed to get member role: $error',
        cause: error,
      );
    }
  }

  /// Returns all members of the document at [docPath].
  ///
  /// Reconstructs [PkMember] instances from the `memberIds` array and
  /// `roles` map stored on the document.
  Future<List<PkMember>> getMembers(String docPath) async {
    try {
      final snapshot = await firestore.doc(docPath).get();
      if (!snapshot.exists) return const [];

      final data = snapshot.data();
      if (data == null) return const [];

      final memberIds = _extractMemberIds(data);
      final roles = _extractRoles(data);
      final now = DateTime.now();

      return memberIds.map((uid) {
        return PkMember(
          userId: uid,
          role: (roles[uid] as String?) ?? 'viewer',
          joinedAt: now,
        );
      }).toList(growable: false);
    } catch (error) {
      throw SharingException(
        message: 'Failed to get members: $error',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  List<String> _extractMemberIds(Map<String, dynamic> data) {
    final raw = data[sharingConfig.memberIdsField];
    if (raw is! List) return const [];
    return raw.cast<String>();
  }

  Map<String, dynamic> _extractRoles(Map<String, dynamic> data) {
    final raw = data[sharingConfig.rolesField];
    if (raw is! Map<String, dynamic>) return const {};
    return raw;
  }
}

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown when a sharing operation fails.
final class SharingException extends PrimekitException {
  const SharingException({required super.message, super.cause})
      : super(code: 'SHARING');

  @override
  String get userMessage => 'Failed to update sharing. Please try again.';
}
