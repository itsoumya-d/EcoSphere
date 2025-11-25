import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RewardType {
  virtual_item, // Profile frames, themes, badges
  real_world,   // Coupons, discounts
  donation,     // Tree planting, ocean cleanup
}

class Reward extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int cost;
  final RewardType type;
  final bool isAvailable;
  final int? stock; // Null means infinite
  final DateTime? expiresAt;
  final String? code; // For coupons
  final String? unlockFeatureId; // For virtual items

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cost,
    required this.type,
    this.isAvailable = true,
    this.stock,
    this.expiresAt,
    this.code,
    this.unlockFeatureId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        cost,
        type,
        isAvailable,
        stock,
        expiresAt,
        code,
        unlockFeatureId,
      ];

  factory Reward.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reward(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      cost: (data['cost'] ?? 0).toInt(),
      type: RewardType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RewardType.virtual_item,
      ),
      isAvailable: data['isAvailable'] ?? true,
      stock: data['stock'],
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      code: data['code'],
      unlockFeatureId: data['unlockFeatureId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'cost': cost,
      'type': type.name,
      'isAvailable': isAvailable,
      'stock': stock,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'code': code,
      'unlockFeatureId': unlockFeatureId,
    };
  }
}
