import 'package:flutter_test/flutter_test.dart';
import 'package:ecosphare/features/community/domain/social_post.dart';

void main() {
  group('SocialPost Model Tests ', () {
    test('should create social post with required fields', () {
      final now = DateTime.now();
      final post = SocialPost(
        id: 'post-123',
        userId: 'user-456',
        userDisplayName: 'Test User',
        content: 'Just saved 5kg of CO2!',
        createdAt: now,
      );

      expect(post.id, 'post-123');
      expect(post.userId, 'user-456');
      expect(post.content, 'Just saved 5kg of CO2!');
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.likedBy, isEmpty);
    });

    test('should handle carbon impact correctly', () {
      final post = SocialPost(
        id: 'post-123',
        userId: 'user-456',
        userDisplayName: 'Test User',
        content: 'Biked to work!',
        carbonImpact: -5.5,
        createdAt: DateTime.now(),
      );

      expect(post.carbonImpact, -5.5);
    });

    test('should track likes correctly', () {
      final post = SocialPost(
        id: 'post-123',
        userId: 'user-456',
        userDisplayName: 'Test User',
        content: 'Test post',
        likedBy: ['user1', 'user2', 'user3'],
        createdAt: DateTime.now(),
      );

      expect(post.likeCount, 3); // likeCount is a getter
      expect(post.likedBy.length, 3);
      expect(post.isLikedBy('user1'), true);
      expect(post.isLikedBy('user999'), false);
    });

    test('should handle activity reference', () {
      final post = SocialPost(
        id: 'post-123',
        userId: 'user-456',
        userDisplayName: 'Test User',
        content: 'Shared my activity!',
        activityId: 'activity-789',
        activityType: 'transport',
        createdAt: DateTime.now(),
      );

      expect(post.activityId, 'activity-789');
      expect(post.activityType, 'transport');
    });

    test('should convert to Firestore correctly', () {
      final now = DateTime.now();
      final post = SocialPost(
        id: 'post-123',
        userId: 'user-456',
        userDisplayName: 'Test User',
        content: 'Test content',
        likedBy: ['user1', 'user2'],
        commentCount: 3,
        createdAt: now,
      );

      final map = post.toFirestore();

      expect(map['userId'], 'user-456');
      expect(map['userDisplayName'], 'Test User');
      expect(map['content'], 'Test content');
      expect(map['likedBy'], ['user1', 'user2']);
      expect(map['commentCount'], 3);
      expect(map['createdAt'], isNotNull);
    });
  });

  group('PostComment Model Tests', () {
    test('should create comment with required fields', () {
      final now = DateTime.now();
      final comment = PostComment(
        id: 'comment-123',
        postId: 'post-456',
        userId: 'user-789',
        userDisplayName: 'Commenter',
        content: 'Great work!',
        createdAt: now,
      );

      expect(comment.id, 'comment-123');
      expect(comment.postId, 'post-456');
      expect(comment.userId, 'user-789');
      expect(comment.content, 'Great work!');
    });

    test('should handle user photo URL', () {
      final comment = PostComment(
        id: 'comment-123',
        postId: 'post-456',
        userId: 'user-789',
        userDisplayName: 'Commenter',
        userPhotoUrl: 'https://example.com/photo.jpg',
        content: 'Nice!',
        createdAt: DateTime.now(),
      );

      expect(comment.userPhotoUrl, 'https://example.com/photo.jpg');
    });

    test('should convert comment to Firestore correctly', () {
      final now = DateTime.now();
      final comment = PostComment(
        id: 'comment-123',
        postId: 'post-456',
        userId: 'user-789',
        userDisplayName: 'Commenter',
        content: 'Test comment',
        createdAt: now,
      );

      final map = comment.toFirestore();

      expect(map['postId'], 'post-456');
      expect(map['userId'], 'user-789');
      expect(map['content'], 'Test comment');
      expect(map['createdAt'], isNotNull);
    });
  });
}
