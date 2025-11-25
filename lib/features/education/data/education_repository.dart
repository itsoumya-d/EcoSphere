import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/article.dart';

/// Repository for educational content
class EducationRepository {
  final FirebaseFirestore _firestore;

  EducationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _articlesCollection => _firestore.collection('articles');
  CollectionReference get _quizzesCollection => _firestore.collection('quizzes');

  // ==================== ARTICLES ====================

  /// Get all articles
  Future<List<Article>> getArticles({ArticleCategory? category}) async {
    try {
      Query query = _articlesCollection.orderBy('publishedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get articles: $e');
    }
  }

  /// Get featured articles
  Future<List<Article>> getFeaturedArticles({int limit = 5}) async {
    try {
      final snapshot = await _articlesCollection
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get featured articles: $e');
    }
  }

  /// Get single article
  Future<Article?> getArticle(String articleId) async {
    try {
      final doc = await _articlesCollection.doc(articleId).get();
      if (!doc.exists) return null;

      // Increment view count
      await _articlesCollection.doc(articleId).update({
        'views': FieldValue.increment(1),
      });

      return Article.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get article: $e');
    }
  }

  /// Search articles
  Future<List<Article>> searchArticles(String query) async {
    try {
      final snapshot = await _articlesCollection.get();
      final articles = snapshot.docs.map((doc) => Article.fromFirestore(doc)).toList();

      // Client-side search (Firestore has limited text search)
      final lowercaseQuery = query.toLowerCase();
      return articles.where((article) {
        return article.title.toLowerCase().contains(lowercaseQuery) ||
            article.summary.toLowerCase().contains(lowercaseQuery) ||
            article.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }

  /// Like article
  Future<void> likeArticle(String articleId) async {
    try {
      await _articlesCollection.doc(articleId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to like article: $e');
    }
  }

  // ==================== QUIZZES ====================

  /// Get all quizzes
  Future<List<Quiz>> getQuizzes({ArticleCategory? category}) async {
    try {
      Query query = _quizzesCollection;

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      final snapshot = await query.get();
      
      final quizzes = <Quiz>[];
      for (final doc in snapshot.docs) {
        final questions = await _getQuizQuestions(doc.id);
        quizzes.add(Quiz.fromFirestore(doc, questions));
      }

      return quizzes;
    } catch (e) {
      throw Exception('Failed to get quizzes: $e');
    }
  }

  /// Get single quiz with questions
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final doc = await _quizzesCollection.doc(quizId).get();
      if (!doc.exists) return null;

      final questions = await _getQuizQuestions(quizId);
      return Quiz.fromFirestore(doc, questions);
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  /// Get quiz questions
  Future<List<QuizQuestion>> _getQuizQuestions(String quizId) async {
    try {
      final snapshot = await _quizzesCollection
          .doc(quizId)
          .collection('questions')
          .get();

      return snapshot.docs
          .map((doc) => QuizQuestion.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get quiz questions: $e');
    }
  }

  /// Save quiz result
  Future<void> saveQuizResult({
    required String userId,
    required String quizId,
    required int score,
    required int totalQuestions,
    required bool passed,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .add({
        'quizId': quizId,
        'score': score,
        'totalQuestions': totalQuestions,
        'passed': passed,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  /// Get user's quiz results
  Future<List<Map<String, dynamic>>> getUserQuizResults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get quiz results: $e');
    }
  }

  // ==================== BOOKMARKS ====================

  /// Bookmark article
  Future<void> bookmarkArticle(String userId, String articleId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(articleId)
          .set({
        'articleId': articleId,
        'bookmarkedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to bookmark article: $e');
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(String userId, String articleId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(articleId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  /// Get bookmarked articles
  Future<List<Article>> getBookmarkedArticles(String userId) async {
    try {
      final bookmarksSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .orderBy('bookmarkedAt', descending: true)
          .get();

      final articleIds = bookmarksSnapshot.docs
          .map((doc) => doc.data()['articleId'] as String)
          .toList();

      if (articleIds.isEmpty) return [];

      final articles = <Article>[];
      for (final articleId in articleIds) {
        final article = await getArticle(articleId);
        if (article != null) articles.add(article);
      }

      return articles;
    } catch (e) {
      throw Exception('Failed to get bookmarked articles: $e');
    }
  }
}

/// Provider for EducationRepository
final educationRepositoryProvider = Provider<EducationRepository>((ref) {
  return EducationRepository(firestore: FirebaseFirestore.instance);
});
