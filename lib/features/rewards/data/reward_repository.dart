import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecosphare/features/rewards/domain/reward.dart';

class RewardRepository {
  final FirebaseFirestore _firestore;

  RewardRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _rewardsCollection =>
      _firestore.collection('rewards');

  CollectionReference _userRewards(String userId) =>
      _firestore.collection('users').doc(userId).collection('redeemedRewards');

  /// Get all available rewards
  Future<List<Reward>> getAvailableRewards() async {
    try {
      final now = DateTime.now();
      final snapshot = await _rewardsCollection
          .where('isAvailable', isEqualTo: true)
          // .where('expiresAt', isGreaterThan: Timestamp.fromDate(now)) // Complex query requires index
          .get();

      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .where((r) => r.expiresAt == null || r.expiresAt!.isAfter(now))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rewards: $e');
    }
  }

  /// Get user's redeemed rewards
  Future<List<Reward>> getUserRewards(String userId) async {
    try {
      final snapshot = await _userRewards(userId)
          .orderBy('redeemedAt', descending: true)
          .get();

      // Note: This stores a copy of the reward at redemption time
      return snapshot.docs
          .map((doc) => Reward.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user rewards: $e');
    }
  }

  /// Redeem a reward
  Future<void> redeemReward({
    required String userId,
    required Reward reward,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        // 1. Check user balance
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('User not found');
        
        final currentPoints = (userDoc.data() as Map<String, dynamic>)['points'] ?? 0;
        if (currentPoints < reward.cost) {
          throw Exception('Insufficient points');
        }

        // 2. Check stock if applicable
        if (reward.stock != null) {
          final rewardRef = _rewardsCollection.doc(reward.id);
          final rewardDoc = await transaction.get(rewardRef);
          final currentStock = (rewardDoc.data() as Map<String, dynamic>)['stock'] ?? 0;
          
          if (currentStock <= 0) {
            throw Exception('Reward out of stock');
          }
          
          // Decrement stock
          transaction.update(rewardRef, {'stock': currentStock - 1});
        }

        // 3. Deduct points
        transaction.update(userRef, {'points': currentPoints - reward.cost});

        // 4. Add to user's rewards
        final redemptionRef = _userRewards(userId).doc();
        final redemptionData = reward.toFirestore();
        redemptionData['redeemedAt'] = FieldValue.serverTimestamp();
        redemptionData['originalRewardId'] = reward.id;
        
        transaction.set(redemptionRef, redemptionData);
      });
    } catch (e) {
      throw Exception('Failed to redeem reward: $e');
    }
  }
}

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepository(firestore: FirebaseFirestore.instance);
});
