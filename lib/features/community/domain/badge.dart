import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Badge rarity levels
enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Badge categories
enum BadgeCategory {
  carbonSaver,   // Carbon reduction achievements
  challenger,    // Challenge completion achievements
  streakMaster,  // Streak-based achievements
  activityLogger, // Activity tracking achievements
  levelMilestone, // Level-based achievements
  socialButterfly, // Community engagement
  earlyAdopter,  // Special/limited badges
}

/// Badge model
class Badge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeRarity rarity;
  final BadgeCategory category;
  final int requiredValue; // The value needed to unlock (e.g., 100 kg CO2, 10 challenges)
  final String unit; // Unit of measurement
  final int xpReward; // XP awarded when unlocked
  final DateTime? unlockedAt; // When user unlocked it (null if locked)
  final bool isSecret; // If true, details hidden until unlocked
  final int sortOrder; // For display ordering

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.rarity,
    required this.category,
    required this.requiredValue,
    required this.unit,
    this.xpReward = 0,
    this.unlockedAt,
    this.isSecret = false,
    this.sortOrder = 0,
  });

  /// Check if badge is unlocked
  bool get isUnlocked => unlockedAt != null;

  /// Get rarity label
  String get rarityLabel {
    switch (rarity) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }

  /// Get rarity color
  String get rarityColor {
    switch (rarity) {
      case BadgeRarity.common:
        return '#9E9E9E'; // Gray
      case BadgeRarity.rare:
        return '#2196F3'; // Blue
      case BadgeRarity.epic:
        return '#9C27B0'; // Purple
      case BadgeRarity.legendary:
        return '#FFD700'; // Gold
    }
  }

  /// Get category label
  String get categoryLabel {
    switch (category) {
      case BadgeCategory.carbonSaver:
        return 'Carbon Saver';
      case BadgeCategory.challenger:
        return 'Challenger';
      case BadgeCategory.streakMaster:
        return 'Streak Master';
      case BadgeCategory.activityLogger:
        return 'Activity Logger';
      case BadgeCategory.levelMilestone:
        return 'Level Milestone';
      case BadgeCategory.socialButterfly:
        return 'Social Butterfly';
      case BadgeCategory.earlyAdopter:
        return 'Early Adopter';
    }
  }

  /// Copy with modifications
  Badge copyWith({
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Badge(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
      rarity: rarity,
      category: category,
      requiredValue: requiredValue,
      unit: unit,
      xpReward: xpReward ?? this.xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isSecret: isSecret,
      sortOrder: sortOrder,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'rarity': rarity.name,
      'category': category.name,
      'requiredValue': requiredValue,
      'unit': unit,
      'xpReward': xpReward,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'isSecret': isSecret,
      'sortOrder': sortOrder,
    };
  }

  /// Create from Firestore document
  factory Badge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Badge(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      iconUrl: data['iconUrl'] as String? ?? '',
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => BadgeCategory.carbonSaver,
      ),
      requiredValue: data['requiredValue'] as int,
      unit: data['unit'] as String,
      xpReward: data['xpReward'] as int? ?? 0,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      isSecret: data['isSecret'] as bool? ?? false,
      sortOrder: data['sortOrder'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        rarity,
        category,
        requiredValue,
        unit,
        xpReward,
        unlockedAt,
        isSecret,
        sortOrder,
      ];
}

/// Predefined badges
class BadgeDefinitions {
  static final List<Badge> all = [
    // Carbon Saver Badges
    Badge(
      id: 'carbon_starter',
      name: 'Carbon Starter',
      description: 'Save your first 10 kg of CO₂',
      iconUrl: '🌱',
      rarity: BadgeRarity.common,
      category: BadgeCategory.carbonSaver,
      requiredValue: 10,
      unit: 'kg CO₂',
      xpReward: 100,
      sortOrder: 1,
    ),
    Badge(
      id: 'carbon_saver',
      name: 'Carbon Saver',
      description: 'Save 100 kg of CO₂',
      iconUrl: '🌿',
      rarity: BadgeRarity.rare,
      category: BadgeCategory.carbonSaver,
      requiredValue: 100,
      unit: 'kg CO₂',
      xpReward: 500,
      sortOrder: 2,
    ),
    Badge(
      id: 'carbon_champion',
      name: 'Carbon Champion',
      description: 'Save 500 kg of CO₂',
      iconUrl: '🌳',
      rarity: BadgeRarity.epic,
      category: BadgeCategory.carbonSaver,
      requiredValue: 500,
      unit: 'kg CO₂',
      xpReward: 2000,
      sortOrder: 3,
    ),
    Badge(
      id: 'carbon_hero',
      name: 'Carbon Hero',
      description: 'Save 1000 kg of CO₂ - a true climate champion!',
      iconUrl: '🏆',
      rarity: BadgeRarity.legendary,
      category: BadgeCategory.carbonSaver,
      requiredValue: 1000,
      unit: 'kg CO₂',
      xpReward: 5000,
      sortOrder: 4,
    ),

    // Challenge Badges
    Badge(
      id: 'challenge_starter',
      name: 'Challenge Starter',
      description: 'Complete your first challenge',
      iconUrl: '⭐',
      rarity: BadgeRarity.common,
      category: BadgeCategory.challenger,
      requiredValue: 1,
      unit: 'challenges',
      xpReward: 100,
      sortOrder: 10,
    ),
    Badge(
      id: 'challenge_enthusiast',
      name: 'Challenge Enthusiast',
      description: 'Complete 10 challenges',
      iconUrl: '🎯',
      rarity: BadgeRarity.rare,
      category: BadgeCategory.challenger,
      requiredValue: 10,
      unit: 'challenges',
      xpReward: 750,
      sortOrder: 11,
    ),
    Badge(
      id: 'challenge_master',
      name: 'Challenge Master',
      description: 'Complete 50 challenges',
      iconUrl: '👑',
      rarity: BadgeRarity.epic,
      category: BadgeCategory.challenger,
      requiredValue: 50,
      unit: 'challenges',
      xpReward: 3000,
      sortOrder: 12,
    ),

    // Streak Badges
    Badge(
      id: 'weekly_streak',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      iconUrl: '🔥',
      rarity: BadgeRarity.common,
      category: BadgeCategory.streakMaster,
      requiredValue: 7,
      unit: 'days',
      xpReward: 200,
      sortOrder: 20,
    ),
    Badge(
      id: 'monthly_streak',
      name: 'Month Master',
      description: 'Maintain a 30-day streak',
      iconUrl: '🔥🔥',
      rarity: BadgeRarity.rare,
      category: BadgeCategory.streakMaster,
      requiredValue: 30,
      unit: 'days',
      xpReward: 1000,
      sortOrder: 21,
    ),
    Badge(
      id: 'century_streak',
      name: 'Century Club',
      description: 'Maintain a 100-day streak - legendary dedication!',
      iconUrl: '💯',
      rarity: BadgeRarity.legendary,
      category: BadgeCategory.streakMaster,
      requiredValue: 100,
      unit: 'days',
      xpReward: 5000,
      sortOrder: 22,
    ),

    // Activity Logger Badges
    Badge(
      id: 'consistent_logger',
      name: 'Consistent Logger',
      description: 'Log 30 activities',
      iconUrl: '📝',
      rarity: BadgeRarity.common,
      category: BadgeCategory.activityLogger,
      requiredValue: 30,
      unit: 'activities',
      xpReward: 150,
      sortOrder: 30,
    ),
    Badge(
      id: 'dedicated_tracker',
      name: 'Dedicated Tracker',
      description: 'Log 100 activities',
      iconUrl: '📊',
      rarity: BadgeRarity.rare,
      category: BadgeCategory.activityLogger,
      requiredValue: 100,
      unit: 'activities',
      xpReward: 500,
      sortOrder: 31,
    ),
    Badge(
      id: 'year_round',
      name: 'Year-Round Tracker',
      description: 'Log 365 activities - a full year!',
      iconUrl: '📅',
      rarity: BadgeRarity.epic,
      category: BadgeCategory.activityLogger,
      requiredValue: 365,
      unit: 'activities',
      xpReward: 3000,
      sortOrder: 32,
    ),

    // Level Milestone Badges
    Badge(
      id: 'level_5',
      name: 'Rising Star',
      description: 'Reach level 5',
      iconUrl: '⬆️',
      rarity: BadgeRarity.common,
      category: BadgeCategory.levelMilestone,
      requiredValue: 5,
      unit: 'level',
      xpReward: 100,
      sortOrder: 40,
    ),
    Badge(
      id: 'level_10',
      name: 'Climate Advocate',
      description: 'Reach level 10',
      iconUrl: '🎖️',
      rarity: BadgeRarity.rare,
      category: BadgeCategory.levelMilestone,
      requiredValue: 10,
      unit: 'level',
      xpReward: 500,
      sortOrder: 41,
    ),
    Badge(
      id: 'level_25',
      name: 'Sustainability Expert',
      description: 'Reach level 25',
      iconUrl: '🏅',
      rarity: BadgeRarity.epic,
      category: BadgeCategory.levelMilestone,
      requiredValue: 25,
      unit: 'level',
      xpReward: 2000,
      sortOrder: 42,
    ),
    Badge(
      id: 'level_50',
      name: 'Eco Legend',
      description: 'Reach level 50 - the ultimate achievement!',
      iconUrl: '👑',
      rarity: BadgeRarity.legendary,
      category: BadgeCategory.levelMilestone,
      requiredValue: 50,
      unit: 'level',
      xpReward: 10000,
      sortOrder: 43,
    ),
  ];

  /// Get badge by ID
  static Badge? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get badges by category
  static List<Badge> getByCategory(BadgeCategory category) {
    return all.where((b) => b.category == category).toList();
  }

  /// Get badges by rarity
  static List<Badge> getByRarity(BadgeRarity rarity) {
    return all.where((b) => b.rarity == rarity).toList();
  }
}
