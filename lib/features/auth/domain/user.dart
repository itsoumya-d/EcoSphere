import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:equatable/equatable.dart';

/// User model representing app user data
class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // User preferences
  final String preferredLanguage;
  final bool isDarkMode;
  final String preferredUnits; // 'metric' or 'imperial'
  
  // User stats (calculated/aggregated)
  final double totalCarbonSaved;
  final int totalActivitiesLogged;
  final int currentStreak;
  final int level;
  final int experiencePoints;
  final int points; // Redeemable currency
  final List<String> unlockedBadgeIds;
  final int challengesCompleted;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.preferredLanguage = 'en',
    this.isDarkMode = false,
    this.preferredUnits = 'metric',
    this.totalCarbonSaved = 0.0,
    this.totalActivitiesLogged = 0,
    this.currentStreak = 0,
    this.level = 1,
    this.experiencePoints = 0,
    this.points = 0,
    this.unlockedBadgeIds = const [],
    this.challengesCompleted = 0,
  });

  /// Create user from Firebase User
  factory AppUser.fromFirebaseUser(
    firebase_auth.User firebaseUser, {
    String? displayName,
    String? photoURL,
  }) {
    final now = DateTime.now();
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: displayName ?? firebaseUser.displayName,
      photoURL: photoURL ?? firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? now,
      updatedAt: now,
    );
  }

  /// Create user from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppUser(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      preferredLanguage: data['preferredLanguage'] as String? ?? 'en',
      isDarkMode: data['isDarkMode'] as bool? ?? false,
      preferredUnits: data['preferredUnits'] as String? ?? 'metric',
      totalCarbonSaved: (data['totalCarbonSaved'] as num?)?.toDouble() ?? 0.0,
      totalActivitiesLogged: data['totalActivitiesLogged'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      points: data['points'] as int? ?? 0,
      unlockedBadgeIds: List<String>.from(data['unlockedBadgeIds'] as List? ?? []),
      challengesCompleted: data['challengesCompleted'] as int? ?? 0,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'preferredLanguage': preferredLanguage,
      'isDarkMode': isDarkMode,
      'preferredUnits': preferredUnits,
      'totalCarbonSaved': totalCarbonSaved,
      'totalActivitiesLogged': totalActivitiesLogged,
      'currentStreak': currentStreak,
      'level': level,
      'experiencePoints': experiencePoints,
      'points': points,
      'unlockedBadgeIds': unlockedBadgeIds,
      'challengesCompleted': challengesCompleted,
    };
  }

  /// Create copy with updated fields
  AppUser copyWith({
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    DateTime? updatedAt,
    String? preferredLanguage,
    bool? isDarkMode,
    String? preferredUnits,
    double? totalCarbonSaved,
    int? totalActivitiesLogged,
    int? currentStreak,
    int? level,
    int? experiencePoints,
    int? points,
    List<String>? unlockedBadgeIds,
    int? challengesCompleted,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      totalCarbonSaved: totalCarbonSaved ?? this.totalCarbonSaved,
      totalActivitiesLogged: totalActivitiesLogged ?? this.totalActivitiesLogged,
      currentStreak: currentStreak ?? this.currentStreak,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      points: points ?? this.points,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        photoURL,
        emailVerified,
        createdAt,
        updatedAt,
        preferredLanguage,
        isDarkMode,
        preferredUnits,
        totalCarbonSaved,
        totalActivitiesLogged,
        currentStreak,
        level,
        experiencePoints,
        points,
        unlockedBadgeIds,
        challengesCompleted,
      ];
}
