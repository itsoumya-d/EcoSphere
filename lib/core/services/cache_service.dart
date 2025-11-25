import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheService {
  static const String _dashboardBox = 'dashboard_box';
  static const String _challengeBox = 'challenge_box';

  Future<void> init() async {
    await Hive.openBox(_dashboardBox);
    await Hive.openBox(_challengeBox);
  }

  Future<void> saveDashboardData(Map<String, dynamic> data) async {
    final box = Hive.box(_dashboardBox);
    await box.put('data', data);
  }

  Map<String, dynamic>? getDashboardData() {
    final box = Hive.box(_dashboardBox);
    return box.get('data') != null
        ? Map<String, dynamic>.from(box.get('data'))
        : null;
  }

  Future<void> saveChallengeData(Map<String, dynamic> data) async {
    final box = Hive.box(_challengeBox);
    await box.put('data', data);
  }

  Map<String, dynamic>? getChallengeData() {
    final box = Hive.box(_challengeBox);
    return box.get('data') != null
        ? Map<String, dynamic>.from(box.get('data'))
        : null;
  }
}

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
