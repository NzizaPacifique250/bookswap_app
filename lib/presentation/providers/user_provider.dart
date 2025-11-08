import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import 'auth_provider.dart';

/// Provider for current user's UserModel from Firestore
final currentUserModelProvider = FutureProvider.family<UserModel?, String>(
  (ref, userId) async {
    final userRepository = ref.watch(userRepositoryProvider);
    return await userRepository.getUser(userId);
  },
);

/// Notifier for user operations
class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final UserRepository _userRepository;
  final Ref _ref;

  UserNotifier(this._userRepository, this._ref)
      : super(const AsyncValue.data(null));

  /// Updates user's display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    state = const AsyncValue.loading();

    try {
      // Check if user document exists
      final userExists = await _userRepository.userExists(userId);
      
      if (!userExists) {
        // Create user document if it doesn't exist
        final authService = _ref.read(authServiceProvider);
        final currentUser = authService.getCurrentUser();
        
        if (currentUser == null) {
          throw Exception('User not found');
        }

        final userModel = UserModel(
          uid: userId,
          email: currentUser.email ?? '',
          displayName: displayName,
          emailVerified: currentUser.emailVerified,
          createdAt: DateTime.now(),
        );

        await _userRepository.createUser(userModel);
      } else {
        // Update existing user document
        await _userRepository.updateUser(
          userId,
          {'displayName': displayName},
        );
      }

      state = const AsyncValue.data(null);

      // Invalidate current user model provider
      _ref.invalidate(currentUserModelProvider(userId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for user notifier
final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserNotifier(userRepository, ref);
});

