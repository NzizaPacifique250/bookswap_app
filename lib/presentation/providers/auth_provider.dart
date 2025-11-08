import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';

/// Provider for AuthService singleton instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for UserRepository singleton instance
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository.instance;
});

/// StreamProvider that listens to authentication state changes
/// 
/// Emits User? - User object when signed in, null when signed out
/// Automatically updates when user signs in/out or token refreshes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});

/// FutureProvider that gets the current user
/// 
/// Returns User? - Current user if signed in, null otherwise
/// Use this for one-time user retrieval
final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUser();
});

/// StateNotifier for managing authentication operations
/// 
/// Handles sign up, sign in, sign out, email verification, and password reset
/// Uses AsyncValue<User?> to manage loading, data, and error states
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final UserRepository _userRepository;

  AuthNotifier(this._authService, this._userRepository)
      : super(const AsyncValue.loading()) {
    // Initialize with current user state
    _initialize();
  }

  /// Initialize the notifier with current auth state
  Future<void> _initialize() async {
    try {
      final user = _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Signs up a new user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// [displayName] - User's display name
  /// 
  /// After successful signup:
  /// - Sends verification email automatically
  /// - Creates user document in Firestore
  /// - Shows success message
  /// 
  /// Updates state to loading during operation, then to data or error
  Future<void> signUp(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      print('[AuthNotifier] Starting sign up for: $email');
      state = const AsyncValue.loading();

      // Sign up user with Firebase Auth
      final userCredential = await _authService.signUpWithEmail(
        email,
        password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed. Please try again.');
      }

      // Create user document in Firestore
      try {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: displayName.trim(),
          emailVerified: user.emailVerified,
          createdAt: DateTime.now(),
          lastLoginAt: null,
        );

        await _userRepository.createUser(userModel);
        print('[AuthNotifier] User document created in Firestore: ${user.uid}');
      } catch (e) {
        print('[AuthNotifier] Error creating user document: $e');
        // Don't fail signup if Firestore creation fails, but log it
        // The user can still use the app, document can be created later
      }

      // Verification email is already sent by AuthService.signUpWithEmail
      print('[AuthNotifier] Sign up successful: ${user.uid}');
      state = AsyncValue.data(user);

      // Note: Success message should be shown by the UI layer
      // using SnackbarUtils or similar
    } catch (e) {
      print('[AuthNotifier] Sign up error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Signs in an existing user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Email verification check has been removed - users can sign in without verifying email.
  /// Updates lastLoginAt in Firestore on successful sign in.
  /// 
  /// Updates state to loading during operation, then to data or error
  Future<void> signIn(String email, String password) async {
    try {
      print('[AuthNotifier] Starting sign in for: $email');
      state = const AsyncValue.loading();

      // Sign in user
      final userCredential = await _authService.signInWithEmail(
        email,
        password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('Sign in failed. Please try again.');
      }

      // Reload user to get latest data
      await _authService.reloadUser();
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('Unable to retrieve user information.');
      }

      // Email verification check removed - users can sign in without verifying email

      // Update last login timestamp in Firestore
      try {
        await _userRepository.updateLastLogin(user.uid);
        print('[AuthNotifier] Last login updated: ${user.uid}');
      } catch (e) {
        print('[AuthNotifier] Error updating last login: $e');
        // Don't fail sign in if last login update fails
      }

      print('[AuthNotifier] Sign in successful: ${user.uid}');
      state = AsyncValue.data(currentUser);
    } catch (e) {
      print('[AuthNotifier] Sign in error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Signs out the current user
  /// 
  /// Clears the authentication state and sets state to null
  /// Updates state to loading during operation, then to data(null) or error
  Future<void> signOut() async {
    try {
      print('[AuthNotifier] Starting sign out');
      state = const AsyncValue.loading();

      await _authService.signOut();

      print('[AuthNotifier] Sign out successful');
      state = const AsyncValue.data(null);
    } catch (e) {
      print('[AuthNotifier] Sign out error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sends verification email to the current user
  /// 
  /// Throws error if no user is signed in
  /// Updates state if operation fails
  Future<void> sendVerificationEmail() async {
    try {
      print('[AuthNotifier] Sending verification email');
      state = const AsyncValue.loading();

      await _authService.sendEmailVerification();

      // Reload user to get updated state
      await _authService.reloadUser();
      final user = _authService.getCurrentUser();

      print('[AuthNotifier] Verification email sent successfully');
      state = AsyncValue.data(user);
    } catch (e) {
      print('[AuthNotifier] Send verification email error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Checks if the current user's email is verified
  /// 
  /// Reloads user data to get latest verification status
  /// Updates state with current user
  /// 
  /// Returns true if verified, false otherwise
  Future<bool> checkEmailVerification() async {
    try {
      print('[AuthNotifier] Checking email verification');
      state = const AsyncValue.loading();

      final isVerified = await _authService.isEmailVerified();
      final user = _authService.getCurrentUser();

      print('[AuthNotifier] Email verification status: $isVerified');
      state = AsyncValue.data(user);

      return isVerified;
    } catch (e) {
      print('[AuthNotifier] Check email verification error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Updates the current user's display name
  /// 
  /// [displayName] - New display name for the user
  /// 
  /// Updates both Firebase Auth and Firestore user document
  Future<void> updateDisplayName(String displayName) async {
    try {
      print('[AuthNotifier] Updating display name');
      
      // Update in Firebase Auth
      await _authService.updateDisplayName(displayName);
      
      // Get updated user
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }

      // Update in Firestore if user document exists
      try {
        final userExists = await _userRepository.userExists(user.uid);
        if (userExists) {
          await _userRepository.updateUser(
            user.uid,
            {'displayName': displayName},
          );
        }
      } catch (e) {
        print('[AuthNotifier] Error updating Firestore: $e');
        // Don't fail if Firestore update fails
      }

      print('[AuthNotifier] Display name updated successfully');
      state = AsyncValue.data(user);
    } catch (e) {
      print('[AuthNotifier] Update display name error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Sends password reset email to the provided email address
  /// 
  /// [email] - Email address to send reset link to
  /// 
  /// Does not change the current auth state
  /// Throws error if email is invalid or not found
  Future<void> resetPassword(String email) async {
    try {
      print('[AuthNotifier] Sending password reset email to: $email');
      
      await _authService.sendPasswordResetEmail(email);

      print('[AuthNotifier] Password reset email sent successfully');
      // Don't update state for password reset
    } catch (e) {
      print('[AuthNotifier] Reset password error: $e');
      rethrow;
    }
  }

  /// Signs in with Google account
  /// 
  /// This method:
  /// - Signs in with Google
  /// - Creates or updates user document in Firestore
  /// - Updates last login timestamp
  /// 
  /// Updates state to loading during operation, then to data or error
  Future<void> signInWithGoogle() async {
    try {
      print('[AuthNotifier] Starting Google sign in');
      state = const AsyncValue.loading();

      // Sign in with Google
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Google sign in failed. Please try again.');
      }

      // Reload user to get latest data
      await _authService.reloadUser();
      final currentUser = _authService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('Unable to retrieve user information.');
      }

      // Check if user document exists in Firestore
      final existingUser = await _userRepository.getUser(user.uid);
      
      if (existingUser == null) {
        // Create new user document
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          emailVerified: user.emailVerified, // Google accounts are pre-verified
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _userRepository.createUser(userModel);
        print('[AuthNotifier] User document created in Firestore: ${user.uid}');
      } else {
        // Update last login timestamp
        await _userRepository.updateLastLogin(user.uid);
        print('[AuthNotifier] Last login updated: ${user.uid}');
      }

      print('[AuthNotifier] Google sign in successful: ${user.uid}');
      state = AsyncValue.data(currentUser);
    } catch (e) {
      print('[AuthNotifier] Google sign in error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Refreshes the current user state
  /// 
  /// Reloads user data from Firebase to get latest information
  /// Useful after email verification or profile updates
  Future<void> refreshUser() async {
    try {
      print('[AuthNotifier] Refreshing user state');
      state = const AsyncValue.loading();

      await _authService.reloadUser();
      final user = _authService.getCurrentUser();

      print('[AuthNotifier] User state refreshed');
      state = AsyncValue.data(user);
    } catch (e) {
      print('[AuthNotifier] Refresh user error: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}

/// StateNotifierProvider for AuthNotifier
/// 
/// Provides access to authentication state and operations throughout the app
/// 
/// Usage:
/// ```dart
/// final authNotifier = ref.watch(authNotifierProvider.notifier);
/// final authState = ref.watch(authNotifierProvider);
/// 
/// // Sign up
/// await authNotifier.signUp('email@example.com', 'password', 'Name');
/// 
/// // Sign in
/// await authNotifier.signIn('email@example.com', 'password');
/// 
/// // Check state
/// authState.when(
///   data: (user) => user != null ? Text('Signed in') : Text('Signed out'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return AuthNotifier(authService, userRepository);
});

