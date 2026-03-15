import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'invite_code.dart';
import 'widgets/invite_share_sheet.dart';
import '../../contacts.dart';

/// Manages invite codes stored as fields on Firestore documents.
///
/// Handles code generation, expiration, lookup, link building,
/// and showing the share sheet — so apps need almost zero invite code.
///
/// ```dart
/// // Configure once (e.g. in a provider or main.dart):
/// final petInvites = FirebaseInviteManager(
///   collection: 'pets',
///   baseUrl: 'https://pawtrack.app',
///   appName: 'PawTrack',
/// );
///
/// // Show share sheet (1 line):
/// await petInvites.showShareSheet(context: context, docId: pet.id,
///     title: 'Invite Member', entityName: pet.name);
///
/// // Join by code:
/// final doc = await petInvites.findByCode('123456');
/// ```
class FirebaseInviteManager {
  FirebaseInviteManager({
    required this.collection,
    this.codeField = 'inviteCode',
    this.createdAtField = 'inviteCodeCreatedAt',
    this.expiration = InviteCode.defaultExpiration,
    this.baseUrl = '',
    this.joinPath = '/join',
    this.appName = '',
    this.showContactsTab = true,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Firestore collection name (e.g. 'pets', 'groups').
  final String collection;

  /// Field name for the invite code on the document.
  final String codeField;

  /// Field name for the code creation timestamp.
  final String createdAtField;

  /// How long codes remain valid.
  final Duration expiration;

  /// App base URL for building invite links.
  final String baseUrl;

  /// Path prefix for join deep links (e.g. '/join').
  final String joinPath;

  /// App name for share messages.
  final String appName;

  /// Whether to show the Contacts tab in the share sheet.
  final bool showContactsTab;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collection);

  /// Gets or creates a non-expired invite code for the given document.
  ///
  /// If the existing code is expired, generates a fresh one.
  Future<String> getOrCreateCode(String docId) async {
    final doc = await _collection.doc(docId).get();
    final data = doc.data();
    final existing = data?[codeField] as String?;
    final createdAtTs = data?[createdAtField] as Timestamp?;

    if (existing != null && createdAtTs != null) {
      if (!InviteCode.isExpired(createdAtTs.toDate(), expiration: expiration)) {
        return existing;
      }
    }

    final now = DateTime.now();
    final code = InviteCode.generateCode();
    await _collection.doc(docId).update({
      codeField: code,
      createdAtField: Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    return code;
  }

  /// Finds a document by its invite code.
  ///
  /// Returns the document snapshot, or `null` if no match or code is expired.
  Future<DocumentSnapshot<Map<String, dynamic>>?> findByCode(
    String code,
  ) async {
    final query = await _collection
        .where(codeField, isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final createdAtTs = doc.data()[createdAtField] as Timestamp?;
    if (createdAtTs != null &&
        InviteCode.isExpired(createdAtTs.toDate(), expiration: expiration)) {
      return null; // expired
    }

    return doc;
  }

  /// Builds the full invite link for a code.
  String buildLink(String code) {
    final base = kIsWeb
        ? '${Uri.base.scheme}://${Uri.base.host}${Uri.base.hasPort ? ':${Uri.base.port}' : ''}'
        : baseUrl;
    return '$base$joinPath/$code';
  }

  /// One-liner: gets code, builds link, shows the share sheet.
  ///
  /// ```dart
  /// await invites.showShareSheet(
  ///   context: context,
  ///   docId: pet.id,
  ///   title: 'Invite Member',
  ///   entityName: pet.name,
  /// );
  /// ```
  Future<void> showShareSheet({
    required BuildContext context,
    required String docId,
    required String title,
    String? subtitle,
    String entityName = '',
    void Function(List<PkContact> contacts)? onContactsInvited,
  }) async {
    final code = await getOrCreateCode(docId);
    final link = buildLink(code);

    if (!context.mounted) return;

    await InviteShareSheet.show(
      context: context,
      inviteCode: code,
      inviteLink: link,
      title: title,
      subtitle: subtitle,
      appName: appName,
      entityName: entityName,
      showContactsTab: showContactsTab,
      onContactsInvited: onContactsInvited,
    );
  }
}
