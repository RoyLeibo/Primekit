import 'package:flutter_contacts/flutter_contacts.dart';

import 'pk_contact.dart';

/// Singleton helper for reading device contacts.
///
/// Filters to contacts that have at least one email, deduplicates by email,
/// and sorts alphabetically by display name.
class ContactsPicker {
  ContactsPicker._();

  static final ContactsPicker _instance = ContactsPicker._();

  /// Returns the singleton instance.
  static ContactsPicker get instance => _instance;

  /// Returns all device contacts that have an email address.
  ///
  /// Results are deduplicated by email and sorted by display name.
  /// Returns an empty list if permission is denied or an error occurs.
  Future<List<PkContact>> getEmailContacts() async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) return [];

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final seen = <String>{};
      final results = <PkContact>[];

      for (final contact in contacts) {
        if (contact.emails.isEmpty) continue;

        final email = contact.emails.first.address;
        if (email.isEmpty || seen.contains(email)) continue;

        seen.add(email);
        results.add(
          PkContact(
            displayName:
                contact.displayName.isNotEmpty ? contact.displayName : email,
            email: email,
            photoBytes: contact.photo,
          ),
        );
      }

      results.sort((a, b) => a.displayName.compareTo(b.displayName));
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Filters [getEmailContacts] by name or email containing [query].
  Future<List<PkContact>> search(String query) async {
    if (query.trim().isEmpty) return getEmailContacts();

    final all = await getEmailContacts();
    final lower = query.toLowerCase();

    return all
        .where(
          (c) =>
              c.displayName.toLowerCase().contains(lower) ||
              c.email.toLowerCase().contains(lower),
        )
        .toList();
  }

  /// Returns `true` if contacts permission is currently granted.
  Future<bool> hasPermission() async {
    return FlutterContacts.requestPermission(readonly: true);
  }

  /// Requests contacts permission from the user.
  Future<bool> requestPermission() async {
    return FlutterContacts.requestPermission(readonly: true);
  }
}
