import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/user.dart';

/// Authentication state
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Authentication controller
class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final AuthRepository _authRepository;

  AuthController({
    required AuthService authService,
    required AuthRepository authRepository,
  })  : _authService = authService,
        _authRepository = authRepository,
        super(const AuthState()) {
    // Initialize by checking current user
    _initializeAuth();
  }

  /// Initialize authentication state
  Future<void> _initializeAuth() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await _loadUser(firebaseUser.uid);
    }
  }

  /// Load user from Firestore
  Future<void> _loadUser(String uid) async {
    try {
      final user = await _authRepository.getUser(uid);
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );

      final user = await _authRepository.getUser(credential.user!.uid);
      if (user == null) {
        throw Exception('User not found in database');
      }

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
      );

      // Create user in Firestore
      final appUser = AppUser.fromFirebaseUser(
        credential.user!,
        displayName: displayName,
      );
      await _authRepository.createUser(appUser);

      state = state.copyWith(
        user: appUser,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _authService.signInWithGoogle();
      final uid = credential.user!.uid;

      // Check if user exists in Firestore
      final exists = await _authRepository.userExists(uid);
      
      AppUser user;
      if (!exists) {
        // Create new user
        user = AppUser.fromFirebaseUser(credential.user!);
        await _authRepository.createUser(user);
      } else {
        // Load existing user
        user = (await _authRepository.getUser(uid))!;
      }

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = await _authService.signInWithApple();
      final uid = credential.user!.uid;

      // Check if user exists in Firestore
      final exists = await _authRepository.userExists(uid);
      
      AppUser user;
      if (!exists) {
        // Create new user
        user = AppUser.fromFirebaseUser(credential.user!);
        await _authRepository.createUser(user);
      } else {
        // Load existing user
        user = (await _authRepository.getUser(uid))!;
      }

      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Update Firebase Auth profile
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Update Firestore
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      
      if (updates.isNotEmpty) {
        await _authRepository.updateUser(state.user!.uid, updates);
      }

      // Reload user
      await _loadUser(state.user!.uid);
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Reload user to check email verification status
  Future<void> reloadUser() async {
    try {
      await _authService.reloadUser();
      if (state.user != null) {
        await _loadUser(state.user!.uid);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}

/// Provider for AuthService  
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    authService: ref.watch(authServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

/// Provider for current user
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});

/// Provider for authentication state stream
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
