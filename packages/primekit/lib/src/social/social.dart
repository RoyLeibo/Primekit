export 'activity_feed.dart'
    show
        ActivityFeed,
        CommentFeedItem,
        CustomFeedItem,
        FeedItem,
        FollowFeedItem,
        LikeFeedItem,
        PostFeedItem;
// activity_feed_source_base.dart: abstract interface only, no Firebase import.
// FirebaseActivityFeedSource requires cloud_firestore — import directly:
// import 'package:primekit/src/social/activity_feed_source.dart' show FirebaseActivityFeedSource;
export 'activity_feed_source_base.dart' show ActivityFeedSource;
// follow_service_base.dart: abstract + service only, no Firebase import.
// FirebaseFollowSource requires cloud_firestore — import directly:
// import 'package:primekit/src/social/follow_service.dart' show FirebaseFollowSource;
export 'follow_service_base.dart' show FollowDataSource, FollowService;
// profile_service_base.dart: abstract interface + service, no Firebase import.
// FirebaseProfileSource requires cloud_firestore — import directly:
// import 'package:primekit/src/social/profile_service.dart' show FirebaseProfileSource;
export 'profile_service_base.dart' show ProfileDataSource, ProfileService;
export 'share_service.dart' show ShareService;
// social_auth_types.dart: platform-agnostic types (no google_sign_in import).
// FirebaseSocialAuth requires Firebase + google_sign_in — import directly:
// import 'package:primekit/src/social/social_auth_provider.dart' show FirebaseSocialAuth;
export 'social_auth_types.dart'
    show SocialAuthResult, SocialAuthService, SocialProvider;
export 'user_profile.dart' show UserProfile;
