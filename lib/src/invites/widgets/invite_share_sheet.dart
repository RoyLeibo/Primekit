import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../contacts.dart';
import 'invite_contacts_tab.dart';

/// A multi-tab bottom sheet for sharing invitations.
///
/// Tabs: Link | Code | Share | (optional) Contacts
///
/// ```dart
/// InviteShareSheet.show(
///   context: context,
///   inviteCode: '123456',
///   inviteLink: 'https://app.com/join/123456',
///   title: 'Invite Member',
///   appName: 'MyApp',
///   entityName: 'Team Alpha',
/// );
/// ```
class InviteShareSheet extends StatefulWidget {
  const InviteShareSheet({
    super.key,
    required this.inviteCode,
    required this.inviteLink,
    required this.title,
    this.subtitle,
    this.appName = '',
    this.entityName = '',
    this.showContactsTab = true,
    this.onContactsInvited,
  });

  final String inviteCode;
  final String inviteLink;
  final String title;
  final String? subtitle;
  final String appName;
  final String entityName;
  final bool showContactsTab;
  final void Function(List<PkContact> contacts)? onContactsInvited;

  /// Shows the invite share sheet as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String inviteCode,
    required String inviteLink,
    required String title,
    String? subtitle,
    String appName = '',
    String entityName = '',
    bool showContactsTab = true,
    void Function(List<PkContact> contacts)? onContactsInvited,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => InviteShareSheet(
        inviteCode: inviteCode,
        inviteLink: inviteLink,
        title: title,
        subtitle: subtitle,
        appName: appName,
        entityName: entityName,
        showContactsTab: showContactsTab,
        onContactsInvited: onContactsInvited,
      ),
    );
  }

  /// Builds the default share message from app/entity names.
  String get _shareMessage {
    final parts = <String>[];
    if (entityName.isNotEmpty) {
      parts.add('Join "$entityName"');
      if (appName.isNotEmpty) parts.add('on $appName');
      parts.add('!');
    } else if (appName.isNotEmpty) {
      parts.add('Join $appName!');
    }
    parts.add('\n\nLink: $inviteLink\nCode: $inviteCode');
    return parts.join(' ');
  }

  @override
  State<InviteShareSheet> createState() => _InviteShareSheetState();
}

class _InviteShareSheetState extends State<InviteShareSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _tabCount => widget.showContactsTab ? 4 : 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Link'),
              const Tab(text: 'Code'),
              const Tab(text: 'Share'),
              if (widget.showContactsTab) const Tab(text: 'Contacts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _LinkTab(
                  link: widget.inviteLink,
                  onCopy: () => _copy(widget.inviteLink, 'Link copied'),
                ),
                _CodeTab(
                  code: widget.inviteCode,
                  onCopy: () => _copy(widget.inviteCode, 'Code copied'),
                ),
                _ShareTab(sheet: widget),
                if (widget.showContactsTab)
                  InviteContactsTab(
                    inviteLink: widget.inviteLink,
                    shareMessage: widget._shareMessage,
                    onContactsInvited: widget.onContactsInvited,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Link tab ──────────────────────────────────────────────────────────────────

class _LinkTab extends StatelessWidget {
  const _LinkTab({required this.link, required this.onCopy});
  final String link;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share this link:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(link,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontFamily: 'monospace')),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }
}

// ── Code tab ──────────────────────────────────────────────────────────────────

class _CodeTab extends StatelessWidget {
  const _CodeTab({required this.code, required this.onCopy});
  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share this code:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(code,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 6),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copy Code'),
          ),
        ],
      ),
    );
  }
}

// ── Share tab ─────────────────────────────────────────────────────────────────

class _ShareTab extends StatelessWidget {
  const _ShareTab({required this.sheet});
  final InviteShareSheet sheet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Share invitation via:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Share.share(
              sheet._shareMessage,
              subject: sheet.entityName.isNotEmpty
                  ? 'Join ${sheet.entityName}'
                  : null,
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share Link & Code'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(14)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Share.share(sheet.inviteLink),
            icon: const Icon(Icons.link_rounded, size: 18),
            label: const Text('Share Link Only'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final msg = sheet.entityName.isNotEmpty
                  ? 'Join "${sheet.entityName}" with code: ${sheet.inviteCode}'
                  : 'Use invite code: ${sheet.inviteCode}';
              Share.share(msg);
            },
            icon: const Icon(Icons.pin_rounded, size: 18),
            label: const Text('Share Code Only'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(130),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withAlpha(80)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Share via Messages, WhatsApp, Email, etc.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
