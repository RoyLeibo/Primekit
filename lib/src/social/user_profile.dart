import 'package:flutter/foundation.dart';

/// An immutable value type representing a user's public profile.
///
/// ```dart
/// final profile = UserProfile(
///   id: 'user_123',
///   displayName: 'Alice',
///   createdAt: DateTime.now(),
/// );
/// final updated = profile.copyWith(bio: 'Flutter developer');
/// ```
@immutable
final class UserProfile {
  /// Creates a [UserProfile].
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.createdAt,
    this.email,
    this.avatarUrl,
    this.bio,
    this.followerCount = 0,
    this.followingCount = 0,
    this.metadata = const {},
  });

  /// Constructs a [UserProfile] from a JSON map (e.g. from Firestore).
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        followerCount: (json['followerCount'] as int?) ?? 0,
        followingCount: (json['followingCount'] as int?) ?? 0,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  /// Unique user identifier.
  final String id;

  /// Display name shown in the UI.
  final String displayName;

  /// When the profile was created.
  final DateTime createdAt;

  /// User's email address (may be null for privacy).
  final String? email;

  /// Public avatar URL.
  final String? avatarUrl;

  /// Optional bio / about text.
  final String? bio;

  /// Number of users following this profile.
  final int followerCount;

  /// Number of users this profile is following.
  final int followingCount;

  /// Arbitrary extra fields (e.g. custom attributes from Firestore).
  final Map<String, dynamic> metadata;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a new [UserProfile] with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? displayName,
    DateTime? createdAt,
    Object? email = _sentinel,
    Object? avatarUrl = _sentinel,
    Object? bio = _sentinel,
    int? followerCount,
    int? followingCount,
    Map<String, dynamic>? metadata,
  }) =>
      UserProfile(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        createdAt: createdAt ?? this.createdAt,
        email: email == _sentinel ? this.email : email as String?,
        avatarUrl: avatarUrl == _sentinel
            ? this.avatarUrl
            : avatarUrl as String?,
        bio: bio == _sentinel ? this.bio : bio as String?,
        followerCount: followerCount ?? this.followerCount,
        followingCount: followingCount ?? this.followingCount,
        metadata: metadata ?? this.metadata,
      );

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Converts this [UserProfile] to a JSON-serialisable map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'createdAt': createdAt.toIso8601String(),
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio != null) 'bio': bio,
        'followerCount': followerCount,
        'followingCount': followingCount,
        'metadata': metadata,
      };

  // ---------------------------------------------------------------------------
  // Equality
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          email == other.email &&
          avatarUrl == other.avatarUrl &&
          bio == other.bio &&
          followerCount == other.followerCount &&
          followingCount == other.followingCount &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        email,
        avatarUrl,
        bio,
        followerCount,
        followingCount,
        createdAt,
      );

  @override
  String toString() =>
      'UserProfile(id: $id, displayName: $displayName)';
}

/// Sentinel for distinguishing `null` from "not provided" in
/// [UserProfile.copyWith].
const Object _sentinel = Object();
