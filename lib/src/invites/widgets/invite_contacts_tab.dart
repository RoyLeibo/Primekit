import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../contacts.dart';

/// Contacts tab for [InviteShareSheet].
///
/// Shows device contacts with multi-select, search, and permission handling.
/// When contacts are selected, tapping "Invite" opens the native share sheet
/// with the invite message.
class InviteContactsTab extends StatefulWidget {
  const InviteContactsTab({
    super.key,
    required this.inviteLink,
    required this.shareMessage,
    this.onContactsInvited,
  });

  /// The invite link to share with selected contacts.
  final String inviteLink;

  /// The full share message.
  final String shareMessage;

  /// Called after the share sheet is dismissed.
  final void Function(List<PkContact> contacts)? onContactsInvited;

  @override
  State<InviteContactsTab> createState() => _InviteContactsTabState();
}

class _InviteContactsTabState extends State<InviteContactsTab> {
  final _searchController = TextEditingController();
  List<PkContact> _contacts = [];
  List<PkContact> _filtered = [];
  final Set<String> _selectedEmails = {};
  bool _isLoading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    final picker = ContactsPicker.instance;
    final hasPermission = await picker.hasPermission();

    if (!hasPermission) {
      final granted = await picker.requestPermission();
      if (!granted) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
        });
        return;
      }
    }

    final contacts = await picker.getEmailContacts();
    setState(() {
      _contacts = contacts;
      _filtered = contacts;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filtered = _contacts);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filtered = _contacts
          .where((c) =>
              c.displayName.toLowerCase().contains(lower) ||
              c.email.toLowerCase().contains(lower))
          .toList();
    });
  }

  void _toggle(PkContact contact) {
    setState(() {
      if (_selectedEmails.contains(contact.email)) {
        _selectedEmails.remove(contact.email);
      } else {
        _selectedEmails.add(contact.email);
      }
    });
  }

  List<PkContact> get _selectedContacts =>
      _contacts.where((c) => _selectedEmails.contains(c.email)).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.contacts_outlined,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Contacts Permission Required',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Grant contacts permission to invite from your contacts.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadContacts,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.contacts_outlined,
                  size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'No Contacts Found',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No contacts with email addresses were found.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: _onSearch,
          ),
        ),
        // Selection count
        if (_selectedEmails.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_selectedEmails.length} contact${_selectedEmails.length == 1 ? '' : 's'} selected',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        // List
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'No contacts match your search',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final contact = _filtered[index];
                    final isSelected =
                        _selectedEmails.contains(contact.email);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggle(contact),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.email),
                      secondary: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: cs.onPrimaryContainer),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Invite button
        if (_selectedEmails.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final selected = _selectedContacts;
                  Share.share(widget.shareMessage);
                  widget.onContactsInvited?.call(selected);
                },
                child: Text(
                  'Invite ${_selectedEmails.length} Contact${_selectedEmails.length == 1 ? '' : 's'}',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
