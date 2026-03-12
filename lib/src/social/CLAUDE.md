# social — Social Features

**Purpose:** Activity feeds, follow graph, user profiles, social auth, and OS share.

**Key exports:**
- `ActivityFeed` — typed feed items: Post, Like, Follow, Comment
- `ActivityFeedSource` — abstract provider for feed data
- `FollowService` — follow/unfollow management
- `ProfileService` — user profile CRUD
- `SocialAuthService` — multi-provider social login (Google, Apple, etc.)
- `UserProfile` — user data value type
- `ShareService` — OS share intent

**Firebase implementations:** `FirebaseSocialFeedSource`, `FirebaseProfileService` (via `firebase.dart`)

**Dependencies:** firebase (conditional), google_sign_in

**Maintenance:** Update when new social auth provider added or feed item types change.
