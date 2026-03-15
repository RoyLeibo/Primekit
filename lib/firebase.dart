/// Firebase adapters — import this file in addition to primekit.dart
/// to use Firebase-backed implementations.
///
/// This replaces the old `package:primekit_firebase/primekit_firebase.dart` import.
library primekit_firebase;

export 'src/firebase/app_initializer.dart';
export 'src/firebase/auth/firebase_auth_interceptor.dart';
export 'src/firebase/crash/firebase_crash_reporter.dart';
export 'src/firebase/media/firebase_storage_uploader.dart';
export 'src/firebase/notifications/push_handler.dart';
export 'src/firebase/notifications/fcm_token_service.dart';
export 'src/firebase/realtime/firebase_rtdb_channel.dart';
export 'src/firebase/realtime/firebase_presence_service.dart';
export 'src/firebase/sync/firestore_sync_source.dart';
export 'src/firebase/flags/firebase_flag_provider.dart';
export 'src/firebase/rbac/firebase_rbac_provider.dart';
export 'src/firebase/social/activity_feed_source.dart';
export 'src/firebase/social/follow_service.dart';
export 'src/firebase/social/profile_service.dart';
export 'src/firebase/social/social_auth_provider.dart';
export 'src/firebase/currency/firestore_currency_rate_source.dart';
export 'src/firebase/chat/firestore_message_datasource.dart';
export 'src/firebase/chat/firestore_message_repository.dart';
export 'src/firebase/chat/firestore_typing_datasource.dart';
