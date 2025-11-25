import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/social_post.dart';

/// Repository for managing social feed posts and comments
class SocialFeedRepository {
  final FirebaseFirestore _firestore;

  SocialFeedRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Posts collection
  CollectionReference get _postsCollection => _firestore.collection('posts');

  /// Comments subcollection for a post
  CollectionReference _commentsCollection(String postId) =>
      _postsCollection.doc(postId).collection('comments');

  // ==================== POSTS ====================

  /// Create a new post
  Future<SocialPost> createPost(SocialPost post) async {
    try {
      final docRef = await _postsCollection.add(post.toFirestore());
      final doc = await docRef.get();
      return SocialPost.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Get recent posts (feed)
  Future<List<SocialPost>> getRecentPosts({int limit = 20}) async {
    try {
      final snapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => SocialPost.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recent posts: $e');
    }
  }

  /// Get posts by user
  Future<List<SocialPost>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      final snapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => SocialPost.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  /// Get a single post
  Future<SocialPost?> getPost(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (!doc.exists) return null;
      return SocialPost.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get post: $e');
    }
  }

  /// Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  /// Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _postsCollection.doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      // Delete all comments first
      final commentsSnapshot = await _commentsCollection(postId).get();
      for (final doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the post
      await _postsCollection.doc(postId).delete();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Stream of recent posts
  Stream<List<SocialPost>> watchRecentPosts({int limit = 20}) {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SocialPost.fromFirestore(doc)).toList());
  }

  // ==================== COMMENTS ====================

  /// Add a comment to a post
  Future<PostComment> addComment(PostComment comment) async {
    try {
      final docRef =
          await _commentsCollection(comment.postId).add(comment.toFirestore());

      // Increment comment count on post
      await _postsCollection.doc(comment.postId).update({
        'commentCount': FieldValue.increment(1),
      });

      final doc = await docRef.get();
      return PostComment.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a post
  Future<List<PostComment>> getComments(String postId, {int limit = 50}) async {
    try {
      final snapshot = await _commentsCollection(postId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PostComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _commentsCollection(postId).doc(commentId).delete();

      // Decrement comment count on post
      await _postsCollection.doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  /// Stream of comments for a post
  Stream<List<PostComment>> watchComments(String postId) {
    return _commentsCollection(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList());
  }
}

/// Provider for SocialFeedRepository
final socialFeedRepositoryProvider = Provider<SocialFeedRepository>((ref) {
  return SocialFeedRepository(firestore: FirebaseFirestore.instance);
});
