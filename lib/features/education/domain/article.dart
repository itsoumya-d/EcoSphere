import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Categories for educational articles
enum ArticleCategory {
  climateScience,
  sustainableLiving,
  carbonFootprint,
  renewableEnergy,
  wasteReduction,
  transportation,
  diet,
  general,
}

/// Educational article model
class Article extends Equatable {
  final String id;
  final String title;
  final String author;
  final String content; // Markdown or HTML
  final String summary;
  final ArticleCategory category;
  final List<String> tags;
  final String? imageUrl;
  final int readTimeMinutes;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final int views;
  final int likes;
  final bool isFeatured;
  final Map<String, dynamic>? metadata;

  const Article({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.summary,
    required this.category,
    this.tags = const [],
    this.imageUrl,
    required this.readTimeMinutes,
    required this.publishedAt,
    required this.updatedAt,
    this.views = 0,
    this.likes = 0,
    this.isFeatured = false,
    this.metadata,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'content': content,
      'summary': summary,
      'category': category.name,
      'tags': tags,
      'imageUrl': imageUrl,
      'readTimeMinutes': readTimeMinutes,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'views': views,
      'likes': likes,
      'isFeatured': isFeatured,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory Article.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Article(
      id: doc.id,
      title: data['title'] as String,
      author: data['author'] as String,
      content: data['content'] as String,
      summary: data['summary'] as String,
      category: ArticleCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ArticleCategory.general,
      ),
      tags: List<String>.from(data['tags'] as List? ?? []),
      imageUrl: data['imageUrl'] as String?,
      readTimeMinutes: data['readTimeMinutes'] as int,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
      isFeatured: data['isFeatured'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        content,
        summary,
        category,
        tags,
        imageUrl,
        readTimeMinutes,
        publishedAt,
        updatedAt,
        views,
        likes,
        isFeatured,
        metadata,
      ];
}

/// Quiz question model
class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? imageUrl;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.imageUrl,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
      'imageUrl': imageUrl,
    };
  }

  factory QuizQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuizQuestion(
      id: doc.id,
      question: data['question'] as String,
      options: List<String>.from(data['options'] as List),
      correctAnswerIndex: data['correctAnswerIndex'] as int,
      explanation: data['explanation'] as String,
      imageUrl: data['imageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        question,
        options,
        correctAnswerIndex,
        explanation,
        imageUrl,
      ];
}

/// Quiz model
class Quiz extends Equatable {
  final String id;
  final String title;
  final String description;
  final ArticleCategory category;
  final List<QuizQuestion> questions;
  final int passingScore; // Percentage
  final int xpReward;
  final DateTime createdAt;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.questions,
    this.passingScore = 70,
    this.xpReward = 50,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'passingScore': passingScore,
      'xpReward': xpReward,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Quiz.fromFirestore(DocumentSnapshot doc, List<QuizQuestion> questions) {
    final data = doc.data() as Map<String, dynamic>;

    return Quiz(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      category: ArticleCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ArticleCategory.general,
      ),
      questions: questions,
      passingScore: data['passingScore'] as int? ?? 70,
      xpReward: data['xpReward'] as int? ?? 50,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        questions,
        passingScore,
        xpReward,
        createdAt,
      ];
}
