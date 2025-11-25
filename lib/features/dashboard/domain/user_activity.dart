import 'package:cloud_firestore/cloud_firestore.dart';
import 'emission_factors.dart';

/// Activity types that users can log
enum ActivityType {
  transport,
  diet,
  energy,
  waste,
  shopping,
}

/// User activity entry
class UserActivity {
  final String id;
  final String userId; // Added for Firestore queries
  final DateTime timestamp;
  final ActivityType type;
  final String category; // e.g., 'car_gasoline', 'beef', etc.
  final double quantity; // miles, servings, kWh, kg, etc.
  final String? notes;
  final double carbonImpact; // kg CO2
  final String? imageUrl; // Optional photo of the activity

  UserActivity({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.type,
    required this.category,
    required this.quantity,
    this.notes,
    required this.carbonImpact,
    this.imageUrl,
  });

  factory UserActivity.create({
    required String userId,
    required ActivityType type,
    required String category,
    required double quantity,
    String? notes,
    String? imageUrl,
  }) {
    final carbonImpact = _calculateImpact(type, category, quantity);
    final now = DateTime.now();
    
    return UserActivity(
      id: '${userId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      timestamp: now,
      type: type,
      category: category,
      quantity: quantity,
      notes: notes,
      carbonImpact: carbonImpact,
      imageUrl: imageUrl,
    );
  }

  static double _calculateImpact(
    ActivityType type,
    String category,
    double quantity,
  ) {
    switch (type) {
      case ActivityType.transport:
        return CarbonCalculator.transportation(
          mode: category,
          miles: quantity,
        );
      case ActivityType.diet:
        return CarbonCalculator.diet(
          foodType: category,
          servings: quantity,
        );
      case ActivityType.energy:
        return CarbonCalculator.energy(
          source: category,
          kwh: quantity,
        );
      case ActivityType.waste:
        return CarbonCalculator.waste(
          wasteType: category,
          kg: quantity,
        );
      case ActivityType.shopping:
        return CarbonCalculator.shopping(
          item: category,
          quantity: quantity.toInt(),
        );
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.name,
      'category': category,
      'quantity': quantity,
      'notes': notes,
      'carbonImpact': carbonImpact,
      'imageUrl': imageUrl,
    };
  }

  /// Create from Firestore document
  factory UserActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserActivity(
      id: doc.id,
      userId: data['userId'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
      ),
      category: data['category'] as String,
      quantity: (data['quantity'] as num).toDouble(),
      notes: data['notes'] as String?,
      carbonImpact: (data['carbonImpact'] as num).toDouble(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'category': category,
      'quantity': quantity,
      'notes': notes,
      'carbonImpact': carbonImpact,
      'imageUrl': imageUrl,
    };
  }

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      category: json['category'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      notes: json['notes'] as String?,
      carbonImpact: (json['carbonImpact'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Get user-friendly activity description
  String getDescription() {
    switch (type) {
      case ActivityType.transport:
        return '${quantity.toStringAsFixed(1)} miles by ${_formatCategory(category)}';
      case ActivityType.diet:
        return '${quantity.toStringAsFixed(0)} serving(s) of ${_formatCategory(category)}';
      case ActivityType.energy:
        return '${quantity.toStringAsFixed(1)} kWh from ${_formatCategory(category)}';
      case ActivityType.waste:
        return '${quantity.toStringAsFixed(1)} kg ${_formatCategory(category)}';
      case ActivityType.shopping:
        return '${quantity.toInt()} ${_formatCategory(category)}';
    }
  }

  String _formatCategory(String cat) {
    return cat.replaceAll('_', ' ').split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Get impact label (positive/negative)
  String getImpactLabel() {
    if (carbonImpact < 0) {
      return 'Saved ${(-carbonImpact).toStringAsFixed(1)} kg CO₂';
    } else {
      return '${carbonImpact.toStringAsFixed(1)} kg CO₂';
    }
  }

  /// Get color based on impact
  bool get isEcoFriendly => carbonImpact < 1.0;
}

/// Quick log presets for common activities
class QuickLogPresets {
  static const List<Map<String, dynamic>> presets = [
    {
      'icon': '🚗',
      'title': 'Drove to work',
      'type': ActivityType.transport,
      'category': 'car_gasoline',
      'quantity': 10.0, // 10 miles avg commute
    },
    {
      'icon': '🚌',
      'title': 'Took the bus',
      'type': ActivityType.transport,
      'category': 'bus',
      'quantity': 10.0,
    },
    {
      'icon': '🚴',
      'title': 'Biked to work',
      'type': ActivityType.transport,
      'category': 'bike',
      'quantity': 10.0,
    },
    {
      'icon': '🥗',
      'title': 'Plant-based meal',
      'type': ActivityType.diet,
      'category': 'vegetables',
      'quantity': 1.0,
    },
    {
      'icon': '🥩',
      'title': 'Ate beef',
      'type': ActivityType.diet,
      'category': 'beef',
      'quantity': 1.0,
    },
    {
      'icon': '🐔',
      'title': 'Ate chicken',
      'type': ActivityType.diet,
      'category': 'chicken',
      'quantity': 1.0,
    },
    {
      'icon': '♻️',
      'title': 'Recycled today',
      'type': ActivityType.waste,
      'category': 'recycled_paper',
      'quantity': 0.5,
    },
    {
      'icon': '🌱',
      'title': 'Composted',
      'type': ActivityType.waste,
      'category': 'composted',
      'quantity': 0.5,
    },
  ];

  static UserActivity createFromPreset(int presetIndex, String userId) {
    final preset = presets[presetIndex];
    return UserActivity.create(
      userId: userId,
      type: preset['type'] as ActivityType,
      category: preset['category'] as String,
      quantity: preset['quantity'] as double,
      notes: preset['title'] as String,
    );
  }
}
