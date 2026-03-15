import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../message.dart';
import '../message_datasource.dart';
import '../message_read_status.dart';
import '../message_repository.dart';
import '../chat_service.dart';

/// Provider for [MessageRemoteDataSource]. Must be overridden in ProviderScope.
final messageRemoteDataSourceProvider =
    Provider<MessageRemoteDataSource>((ref) {
  throw UnimplementedError(
    'messageRemoteDataSourceProvider must be overridden',
  );
});

/// Provider for [MessageRepository]. Must be overridden in ProviderScope.
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  throw UnimplementedError(
    'messageRepositoryProvider must be overridden',
  );
});

/// Provider for [ChatService]. Must be overridden in ProviderScope.
final chatServiceProvider = Provider<ChatService>((ref) {
  throw UnimplementedError(
    'chatServiceProvider must be overridden',
  );
});

/// Provider for [TypingIndicatorDataSource]. Must be overridden in ProviderScope.
final typingIndicatorDataSourceProvider =
    Provider<TypingIndicatorDataSource>((ref) {
  throw UnimplementedError(
    'typingIndicatorDataSourceProvider must be overridden',
  );
});

/// Real-time message stream for a group. Newest first.
final groupMessagesProvider =
    StreamProvider.autoDispose.family<List<Message>, String>((ref, groupId) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchGroupMessages(groupId);
});

/// Real-time read status for a user in a group.
final messageReadStatusProvider = StreamProvider.autoDispose
    .family<MessageReadStatus?, ({String groupId, String userId})>(
        (ref, params) {
  final repository = ref.watch(messageRepositoryProvider);
  return repository.watchReadStatus(
    groupId: params.groupId,
    userId: params.userId,
  );
});

/// Real-time typing users for a group (excludes current user).
final typingUsersProvider = StreamProvider.autoDispose
    .family<List<String>, ({String groupId, String currentUserId})>(
        (ref, params) {
  final dataSource = ref.watch(typingIndicatorDataSourceProvider);
  return dataSource.watchTypingUsers(
    groupId: params.groupId,
    currentUserId: params.currentUserId,
  );
});
