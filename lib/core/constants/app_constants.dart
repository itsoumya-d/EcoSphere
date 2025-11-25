/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'EcoSphere';
  static const String appVersion = '1.0.0';
  
  // Feature Flags
  static const bool enableAppleSignIn = true;
  static const bool enableBiometricAuth = false;
  static const bool enableImageUpload = true;
  static const bool enableLocationTracking = true;
  
  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String challengesCollection = 'challenges';
  static const String challengeProgressCollection = 'challenge_progress';
  static const String leaderboardCollection = 'leaderboard';
  static const String socialFeedCollection = 'social_feed';
  static const String articlesCollection = 'articles';
  static const String resourcesCollection = 'resources';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int activitiesPageSize = 50;
  static const int leaderboardPageSize = 100;
  
  // Carbon Calculation Constants
  static const double usAverageDailyCO2 = 43.8; // kg CO2 per day
  static const double targetDailyCO2 = 13.7; // kg CO2 per day (sustainable)
  static const double globalAverageDailyCO2 = 11.0; // kg CO2 per day
  
  // Gamification
  static const int xpPerActivity = 10;
  static const int xpPerChallenge = 50;
  static const int xpPerLevel = 100;
  static const int basePointsPerKgCO2Saved = 10;
  
  // Streak
  static const int streakBonusMultiplier = 5; // Extra XP per day of streak
  static const int maxStreakBonusDays = 30; // Cap on streak bonus
  
  // Image Upload
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Activity Limits
  static const int maxActivitiesPerDay = 50;
  static const int maxNotesLength = 500;
  
  // Date Ranges
  static const int dashboardDefaultDays = 30;
  static const int statisticsDefaultDays = 90;
  
  // Network
  static const int apiTimeoutSeconds = 30;
  static const int retryAttempts = 3;
  
  // Cache
  static const int cacheDurationMinutes = 5;
  static const int maxCacheSize = 100; // MB
  
  // Units
  static const String metricDistanceUnit = 'km';
  static const String imperialDistanceUnit = 'miles';
  static const String metricWeightUnit = 'kg';
  static const String imperialWeightUnit = 'lbs';
  
  // Conversion Factors
  static const double kmToMiles = 0.621371;
  static const double milesToKm = 1.60934;
  static const double kgToLbs = 2.20462;
  static const double lbsToKg = 0.453592;
  
  // URLs
  static const String privacyPolicyUrl = 'https://ecosphere.app/privacy';
  static const String termsOfServiceUrl = 'https://ecosphere.app/terms';
  static const String supportEmail = 'support@ecosphere.app';
  static const String websiteUrl = 'https://ecosphere.app';
  
  // Social
  static const String twitterHandle = '@ecosphereapp';
  static const String instagramHandle = '@ecosphereapp';
  
  // Analytics Events
  static const String eventActivityLogged = 'activity_logged';
  static const String eventChallengeJoined = 'challenge_joined';
  static const String eventChallengeCompleted = 'challenge_completed';
  static const String eventLevelUp = 'level_up';
  static const String eventShareActivity = 'share_activity';
  static const String eventArticleRead = 'article_read';
  
  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorAuth = 'Authentication error. Please sign in again.';
  static const String errorPermission = 'Permission denied.';
  
  // Success Messages
  static const String successActivityLogged = 'Activity logged successfully!';
  static const String successChallengeJoined = 'Challenge joined!';
  static const String successProfileUpdated = 'Profile updated successfully!';
}

/// Environment configuration
class Environment {
  static const bool isDevelopment = bool.fromEnvironment('DEBUG', defaultValue: true);
  static const bool isProduction = !isDevelopment;
  
  static const String firestoreEmulatorHost = 'localhost:8080';
  static const String authEmulatorHost = 'localhost:9099';
  
  static bool get useEmulators => isDevelopment;
}

/// UI Constants
class UIConstants {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double borderRadiusS = 8.0;
  static const double borderRadiusM = 12.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;
  static const double borderRadiusCircle = 999.0;
  
  // Icon Sizes
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  
  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  // Bottom Sheet
  static const double bottomSheetMinHeight = 200.0;
  static const double bottomSheetMaxHeight = 600.0;
  
  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;
  
  // Cards
  static const double cardElevation = 0.0;
  static const double cardBorderWidth = 1.0;
  
  // Buttons
  static const double buttonHeight = 48.0;
  static const double buttonMinWidth = 88.0;
}
