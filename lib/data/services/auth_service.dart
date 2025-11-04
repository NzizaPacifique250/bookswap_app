import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

/// Authentication service for handling user authentication operations
/// Uses singleton pattern to ensure single instance across the app
class AuthService {
  // Private constructor
  AuthService._();

  // Singleton instance
  static AuthService? _instance;

  /// Get singleton instance
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  /// Get FirebaseAuth instance from FirebaseService
  FirebaseAuth get _auth => FirebaseService.instance.auth;

  /// Signs up a new user with email and password
  ///
  /// [email] - User's email address
  /// [password] - User's password (must meet Firebase requirements)
  ///
  /// Returns [UserCredential] if successful
  /// Throws [FirebaseAuthException] with user-friendly error message on failure
  ///
  /// Common errors handled:
  /// - email-already-in-use: Email is already registered
  /// - weak-password: Password is too weak
  /// - invalid-email: Email format is invalid
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      print('[AuthService] Attempting to sign up user with email: $email');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('[AuthService] User signed up successfully: ${userCredential.user?.uid}');
      
      // Send email verification after successful signup
      await sendEmailVerification();
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Sign up error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected sign up error: $e');
      throw Exception('An unexpected error occurred during sign up. Please try again.');
    }
  }

  /// Sends email verification to the current user
  ///
  /// Throws exception if:
  /// - No user is currently signed in
  /// - Email is already verified
  /// - Network error occurs
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        print('[AuthService] Cannot send verification: No user signed in');
        throw Exception('No user is signed in. Please sign up or sign in first.');
      }

      if (user.emailVerified) {
        print('[AuthService] Email already verified for user: ${user.uid}');
        throw Exception('Your email is already verified.');
      }

      print('[AuthService] Sending verification email to: ${user.email}');
      await user.sendEmailVerification();
      print('[AuthService] Verification email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Send verification error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected send verification error: $e');
      rethrow;
    }
  }

  /// Signs in an existing user with email and password
  ///
  /// [email] - User's email address
  /// [password] - User's password
  ///
  /// Returns [UserCredential] if successful
  /// Throws exception if:
  /// - Email is not verified (checked before returning)
  /// - User not found
  /// - Wrong password
  /// - Invalid email format
  ///
  /// Note: This method checks if the email is verified before allowing sign in.
  /// If email is not verified, it throws an error asking user to verify their email.
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      print('[AuthService] Attempting to sign in user with email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Reload user to get latest email verification status
      await userCredential.user?.reload();
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('[AuthService] Sign in error: User is null after sign in');
        throw Exception('Sign in failed. Please try again.');
      }

      // Check if email is verified
      if (!currentUser.emailVerified) {
        print('[AuthService] Sign in blocked: Email not verified for user: ${currentUser.uid}');
        await signOut(); // Sign out the user since email is not verified
        throw Exception(
          'Please verify your email address before signing in. '
          'Check your inbox for the verification email.',
        );
      }

      print('[AuthService] User signed in successfully: ${currentUser.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Sign in error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected sign in error: $e');
      // If it's already our custom exception, rethrow it
      if (e.toString().contains('verify your email')) {
        rethrow;
      }
      throw Exception('An unexpected error occurred during sign in. Please try again.');
    }
  }

  /// Signs out the current user
  ///
  /// Throws exception if sign out fails
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      print('[AuthService] Attempting to sign out user: ${user?.uid}');
      
      await _auth.signOut();
      print('[AuthService] User signed out successfully');
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Sign out error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected sign out error: $e');
      throw Exception('An error occurred during sign out. Please try again.');
    }
  }

  /// Sends password reset email to the provided email address
  ///
  /// [email] - Email address to send password reset link to
  ///
  /// Throws exception if:
  /// - Email is not registered
  /// - Invalid email format
  /// - Network error occurs
  ///
  /// Note: This method will succeed even if the email is not registered
  /// (for security reasons, Firebase doesn't reveal if an email exists)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('[AuthService] Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('[AuthService] Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected password reset error: $e');
      throw Exception('An error occurred while sending password reset email. Please try again.');
    }
  }

  /// Reloads the current user's data from Firebase
  ///
  /// This is useful to refresh user data, especially email verification status,
  /// after the user verifies their email or updates their profile.
  ///
  /// Throws exception if no user is signed in or reload fails
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        print('[AuthService] Cannot reload: No user signed in');
        throw Exception('No user is signed in.');
      }

      print('[AuthService] Reloading user data: ${user.uid}');
      await user.reload();
      print('[AuthService] User data reloaded successfully');
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Reload user error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected reload error: $e');
      throw Exception('An error occurred while reloading user data. Please try again.');
    }
  }

  /// Returns a stream of authentication state changes
  ///
  /// This stream emits events when:
  /// - User signs in
  /// - User signs out
  /// - User's token is refreshed
  /// - User's email is verified
  ///
  /// Returns Stream<User?> where:
  /// - User object if user is signed in
  /// - null if user is signed out
  ///
  /// Example usage:
  /// ```dart
  /// authStateChanges().listen((User? user) {
  ///   if (user != null) {
  ///     print('User signed in: ${user.uid}');
  ///   } else {
  ///     print('User signed out');
  ///   }
  /// });
  /// ```
  Stream<User?> authStateChanges() {
    print('[AuthService] Setting up auth state changes stream');
    return _auth.authStateChanges();
  }

  /// Gets the currently signed-in user
  ///
  /// Returns [User] if user is signed in, null otherwise
  ///
  /// Note: This returns the cached user. To get the latest user data
  /// (e.g., after email verification), call [reloadUser()] first.
  User? getCurrentUser() {
    final user = _auth.currentUser;
    print('[AuthService] Getting current user: ${user?.uid ?? 'null'}');
    return user;
  }

  /// Checks if the current user's email is verified
  ///
  /// Returns true if email is verified, false otherwise
  ///
  /// Throws exception if no user is signed in
  ///
  /// Note: This checks the cached user data. To get the latest verification
  /// status, call [reloadUser()] first.
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      
      if (user == null) {
        print('[AuthService] Cannot check verification: No user signed in');
        throw Exception('No user is signed in.');
      }

      // Reload user to get latest verification status
      await reloadUser();
      final isVerified = user.emailVerified;
      print('[AuthService] Email verification status for ${user.uid}: $isVerified');
      return isVerified;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Check verification error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] Unexpected check verification error: $e');
      rethrow;
    }
  }

  /// Handles FirebaseAuthException and returns user-friendly error messages
  ///
  /// [exception] - The FirebaseAuthException to handle
  ///
  /// Returns Exception with user-friendly error message
  Exception _handleAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return Exception('No account found with this email address.');
      
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      
      case 'weak-password':
        return Exception('Password is too weak. Please use a stronger password.');
      
      case 'invalid-email':
        return Exception('Invalid email address. Please enter a valid email.');
      
      case 'user-disabled':
        return Exception('This account has been disabled. Please contact support.');
      
      case 'too-many-requests':
        return Exception('Too many attempts. Please try again later.');
      
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled. Please contact support.');
      
      case 'network-request-failed':
        return Exception('Network error. Please check your internet connection.');
      
      case 'invalid-credential':
        return Exception('Invalid email or password. Please try again.');
      
      case 'invalid-verification-code':
        return Exception('Invalid verification code. Please try again.');
      
      case 'invalid-verification-id':
        return Exception('Verification session expired. Please try again.');
      
      case 'requires-recent-login':
        return Exception('Please sign out and sign in again to perform this action.');
      
      default:
        return Exception(
          exception.message ?? 'An authentication error occurred. Please try again.',
        );
    }
  }
}

