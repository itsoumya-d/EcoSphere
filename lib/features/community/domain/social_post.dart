import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a social feed post about an eco-activity
class SocialPost extends Equatable {
  final String id;
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final String content; // The post text/description
  final String? activityId; // Reference to UserActivity if shared
  final String? activityType; // E.g., "transport", "diet"
  final double? carbonImpact; // Carbon saved/emitted
  final String? imageUrl; // Optional image
  final List<String> likedBy; // User IDs who liked this
  final int commentCount;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    required this.content,
    this.activityId,
    this.activityType,
    this.carbonImpact,
    this.imageUrl,
    this.likedBy = const [],
    this.commentCount = 0,
    required this.createdAt,
    this.metadata,
  });

  /// Get like count
  int get likeCount => likedBy.length;

  /// Check if user has liked this post
  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'activityId': activityId,
      'activityType': activityType,
      'carbonImpact': carbonImpact,
      'imageUrl': imageUrl,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory SocialPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SocialPost(
      id: doc.id,
      userId: data['userId'] as String,
      userDisplayName: data['userDisplayName'] as String,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      content: data['content'] as String,
      activityId: data['activityId'] as String?,
      activityType: data['activityType'] as String?,
      carbonImpact: (data['carbonImpact'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'] as String?,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userDisplayName,
        userPhotoUrl,
        content,
        activityId,
        activityType,
        carbonImpact,
        imageUrl,
        likedBy,
        commentCount,
        createdAt,
        metadata,
      ];
}

/// Represents a comment on a social post
class PostComment extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create from Firestore document
  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PostComment(
      id: doc.id,
      postId: data['postId'] as String,
      userId: data['userId'] as String,
      userDisplayName: data['userDisplayName'] as String,
      userPhotoUrl: data['userPhotoUrl'] as String?,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        userDisplayName,
        userPhotoUrl,
        content,
        createdAt,
      ];
}
