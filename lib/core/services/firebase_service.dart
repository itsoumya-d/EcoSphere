import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Singleton service for managing Firebase initialization and service access
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  /// Firebase Authentication instance
  FirebaseAuth get auth => FirebaseAuth.instance;

  /// Cloud Firestore instance
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Firebase Storage instance
  FirebaseStorage get storage => FirebaseStorage.instance;

  /// Firebase Analytics instance
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Initialize Firebase services
  /// Called from main.dart before runApp
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Firebase is already initialized in main.dart
      // This method ensures all services are ready
      
      // Enable Firestore offline persistence
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      _initialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Firebase services: $e');
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized => _initialized;
}
