import 'dart:async';

import 'package:flutter/material.dart';

import '../sync/sync_status.dart';

/// A compact badge that visualises the current sync status.
///
/// Consumes two plain [Stream]s — no Riverpod or other state-management
/// dependency required.
///
/// - Shows nothing when fully synced with 0 pending changes.
/// - Shows an offline indicator, a syncing spinner, or a pending-count badge.
class PkSyncStatusBadge extends StatelessWidget {
  const PkSyncStatusBadge({
    required this.statusStream,
    required this.pendingCountStream,
    this.onRetry,
    super.key,
  });

  final Stream<PkSyncStatus> statusStream;
  final Stream<int> pendingCountStream;

  /// Called when the user taps the badge in [PkSyncStatus.error] state.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PkSyncStatus>(
      stream: statusStream,
      initialData: PkSyncStatus.synced,
      builder: (context, statusSnapshot) {
        final status = statusSnapshot.data ?? PkSyncStatus.synced;

        return StreamBuilder<int>(
          stream: pendingCountStream,
          initialData: 0,
          builder: (context, countSnapshot) {
            final pendingCount = countSnapshot.data ?? 0;

            if (status == PkSyncStatus.synced && pendingCount == 0) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: status == PkSyncStatus.error ? onRetry : null,
              child: Tooltip(
                message: _tooltipMessage(status, pendingCount),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status, context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor(
                          status,
                          context,
                        ).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLeadingIcon(status),
                      const SizedBox(width: 8),
                      Text(
                        _statusText(status, pendingCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeadingIcon(PkSyncStatus status) {
    if (status == PkSyncStatus.syncing) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Icon(_statusIcon(status), size: 18, color: Colors.white);
  }

  static Color _statusColor(PkSyncStatus status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case PkSyncStatus.synced:
      case PkSyncStatus.syncing:
        return theme.colorScheme.primary;
      case PkSyncStatus.offline:
        return Colors.orange;
      case PkSyncStatus.error:
        return theme.colorScheme.error;
    }
  }

  static IconData _statusIcon(PkSyncStatus status) {
    switch (status) {
      case PkSyncStatus.synced:
        return Icons.check_circle;
      case PkSyncStatus.syncing:
        return Icons.sync;
      case PkSyncStatus.offline:
        return Icons.cloud_off;
      case PkSyncStatus.error:
        return Icons.error;
    }
  }

  static String _statusText(PkSyncStatus status, int pendingCount) {
    switch (status) {
      case PkSyncStatus.synced:
        return 'All synced';
      case PkSyncStatus.syncing:
        return pendingCount > 0 ? 'Syncing $pendingCount...' : 'Syncing...';
      case PkSyncStatus.offline:
        return pendingCount > 0 ? 'Offline ($pendingCount pending)' : 'Offline';
      case PkSyncStatus.error:
        return 'Sync error';
    }
  }

  static String _tooltipMessage(PkSyncStatus status, int pendingCount) {
    switch (status) {
      case PkSyncStatus.synced:
        return 'All changes synced to cloud';
      case PkSyncStatus.syncing:
        return 'Syncing $pendingCount ${pendingCount == 1 ? 'change' : 'changes'} to cloud...';
      case PkSyncStatus.offline:
        if (pendingCount > 0) {
          return 'You are offline. $pendingCount ${pendingCount == 1 ? 'change' : 'changes'} will sync when you reconnect.';
        }
        return 'You are offline. Changes will sync when you reconnect.';
      case PkSyncStatus.error:
        return 'Failed to sync changes. Tap to retry.';
    }
  }
}
