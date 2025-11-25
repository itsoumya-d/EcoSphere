import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Challenge difficulty levels
enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}

/// Challenge categories matching activity types
enum ChallengeCategory {
  transport,
  diet,
  energy,
  waste,
  shopping,
  mixed, // Combines multiple categories
}

/// Challenge duration types
enum ChallengeDuration {
  daily,   // 24 hours
  weekly,  // 7 days
  monthly, // 30 days
  custom,  // Custom duration
}

/// User's progress on a specific challenge
class ChallengeProgress extends Equatable {
  final String userId;
  final String challengeId;
  final double currentProgress; // 0.0 to 1.0 (or actual value for countable challenges)
  final double targetProgress;
  final DateTime joinedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final Map<String, dynamic>? metadata; // Additional tracking data

  const ChallengeProgress({
    required this.userId,
    required this.challengeId,
    required this.currentProgress,
    required this.targetProgress,
    required this.joinedAt,
    this.completedAt,
    this.isCompleted = false,
    this.metadata,
  });

  /// Progress percentage (0-100)
  double get progressPercentage =>
      (currentProgress / targetProgress * 100).clamp(0, 100);

  /// Check if challenge is completed
  bool get shouldComplete => currentProgress >= targetProgress;

  /// Copy with modifications
  ChallengeProgress copyWith({
    double? currentProgress,
    DateTime? completedAt,
    bool? isCompleted,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeProgress(
      userId: userId,
      challengeId: challengeId,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress,
      joinedAt: joinedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentProgress': currentProgress,
      'targetProgress': targetProgress,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory ChallengeProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChallengeProgress(
      userId: data['userId'] as String,
      challengeId: data['challengeId'] as String,
      currentProgress: (data['currentProgress'] as num).toDouble(),
      targetProgress: (data['targetProgress'] as num).toDouble(),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      isCompleted: data['isCompleted'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        challengeId,
        currentProgress,
        targetProgress,
        joinedAt,
        completedAt,
        isCompleted,
        metadata,
      ];
}

/// Eco Challenge model
class EcoChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeDuration durationType;
  final int durationDays; // For custom durations
  final double targetValue; // The goal value (e.g., 50 km by bike, 5 plant-based meals)
  final String targetUnit; // Unit of measurement
  final int xpReward;
  final int pointsReward;
  final List<String> badgeIds; // Badges awarded on completion
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final bool isActive;
  final bool isSeasonal;
  final List<String>? tips; // Helpful tips for completing the challenge
  final Map<String, dynamic>? metadata;

  const EcoChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.difficulty,
    required this.durationType,
    this.durationDays = 7,
    required this.targetValue,
    required this.targetUnit,
    required this.xpReward,
    required this.pointsReward,
    this.badgeIds = const [],
    required this.startDate,
    required this.endDate,
    this.participantCount = 0,
    this.isActive = true,
    this.isSeasonal = false,
    this.tips,
    this.metadata,
  });

  /// Get difficulty color
  String get difficultyLabel {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'Easy';
      case ChallengeDifficulty.medium:
        return 'Medium';
      case ChallengeDifficulty.hard:
        return 'Hard';
      case ChallengeDifficulty.expert:
        return 'Expert';
    }
  }

  /// Get category label
  String get categoryLabel {
    switch (category) {
      case ChallengeCategory.transport:
        return 'Transportation';
      case ChallengeCategory.diet:
        return 'Diet';
      case ChallengeCategory.energy:
        return 'Energy';
      case ChallengeCategory.waste:
        return 'Waste';
      case ChallengeCategory.shopping:
        return 'Shopping';
      case ChallengeCategory.mixed:
        return 'Mixed';
    }
  }

  /// Check if challenge is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Copy with modifications
  EcoChallenge copyWith({
    String? title,
    String? description,
    String? imageUrl,
    int? participantCount,
    bool? isActive,
    bool? isSeasonal,
  }) {
    return EcoChallenge(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category,
      difficulty: difficulty,
      durationType: durationType,
      durationDays: durationDays,
      targetValue: targetValue,
      targetUnit: targetUnit,
      xpReward: xpReward,
      pointsReward: pointsReward,
      badgeIds: badgeIds,
      startDate: startDate,
      endDate: endDate,
      participantCount: participantCount ?? this.participantCount,
      isActive: isActive ?? this.isActive,
      isSeasonal: isSeasonal ?? this.isSeasonal,
      tips: tips,
      metadata: metadata,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.name,
      'difficulty': difficulty.name,
      'durationType': durationType.name,
      'durationDays': durationDays,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'xpReward': xpReward,
      'pointsReward': pointsReward,
      'badgeIds': badgeIds,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participantCount': participantCount,
      'isActive': isActive,
      'isSeasonal': isSeasonal,
      'tips': tips,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory EcoChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EcoChallenge(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String? ?? '',
      category: ChallengeCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ChallengeCategory.mixed,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.medium,
      ),
      durationType: ChallengeDuration.values.firstWhere(
        (e) => e.name == data['durationType'],
        orElse: () => ChallengeDuration.weekly,
      ),
      durationDays: data['durationDays'] as int? ?? 7,
      targetValue: (data['targetValue'] as num).toDouble(),
      targetUnit: data['targetUnit'] as String,
      xpReward: data['xpReward'] as int,
      pointsReward: data['pointsReward'] as int,
      badgeIds: (data['badgeIds'] as List<dynamic>?)?.cast<String>() ?? [],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participantCount: data['participantCount'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      isSeasonal: data['isSeasonal'] as bool? ?? false,
      tips: (data['tips'] as List<dynamic>?)?.cast<String>(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        category,
        difficulty,
        durationType,
        durationDays,
        targetValue,
        targetUnit,
        xpReward,
        pointsReward,
        badgeIds,
        startDate,
        endDate,
        participantCount,
        isActive,
        isSeasonal,
        tips,
        metadata,
      ];
}
