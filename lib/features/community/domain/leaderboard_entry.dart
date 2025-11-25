import 'package:equatable/equatable.dart';
import '../../auth/domain/user.dart';

/// Represents a user's entry in a leaderboard
class LeaderboardEntry extends Equatable {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final double score; // Can be XP or Carbon Saved
  final int rank;
  final String? formattedScore; // E.g. "1,200 XP" or "50 kg"
  final int level; // Useful for display

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.score,
    required this.rank,
    this.formattedScore,
    this.level = 1,
  });

  /// Create entry from AppUser
  factory LeaderboardEntry.fromUser(AppUser user, int rank, {bool useCarbon = false}) {
    return LeaderboardEntry(
      userId: user.uid,
      displayName: user.displayName ?? 'Anonymous User',
      photoUrl: user.photoURL,
      score: useCarbon ? user.totalCarbonSaved : user.experiencePoints.toDouble(),
      rank: rank,
      formattedScore: useCarbon 
          ? '${user.totalCarbonSaved.toStringAsFixed(1)} kg' 
          : '${user.experiencePoints} XP',
      level: user.level,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        photoUrl,
        score,
        rank,
        formattedScore,
        level,
      ];
}
