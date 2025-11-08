import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'auth_provider.dart';

/// Provider for chat repository
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository.instance;
});

/// Provider for user chats
final userChatsProvider = StreamProvider.family<List<ChatModel>, String>(
  (ref, userId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getUserChats(userId);
  },
);

/// Notifier for chat operations
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final ChatRepository _chatRepository;
  final UserRepository _userRepository;
  final Ref _ref;

  ChatNotifier(
    this._chatRepository,
    this._userRepository,
    this._ref,
  ) : super(const AsyncValue.data(null));

  /// Gets or creates a chat with a book owner
  /// 
  /// Uses book owner information directly from the book model instead of
  /// fetching from UserRepository, since the owner might not exist in users collection
  Future<String> getOrCreateChatWithBookOwner({
    required String currentUserId,
    required String bookOwnerId,
    required String bookOwnerName,
    required String bookOwnerEmail,
    String? bookId,
    String? bookTitle,
    String? bookImageUrl,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Get current user info (should exist since they're logged in)
      final currentUser = await _userRepository.getUser(currentUserId);
      String currentUserName;
      String currentUserEmail;

      if (currentUser != null) {
        currentUserName = currentUser.displayName;
        currentUserEmail = currentUser.email;
      } else {
        // Fallback: try to get from Firebase Auth
        final authService = _ref.read(authServiceProvider);
        final firebaseUser = await authService.getCurrentUser();
        if (firebaseUser == null) {
          throw Exception('Current user not found');
        }
        currentUserName = firebaseUser.displayName ?? 'User';
        currentUserEmail = firebaseUser.email ?? '';
      }

      // Get or create chat using book owner info directly
      final chatId = await _chatRepository.getOrCreateChat(
        userId1: currentUserId,
        userName1: currentUserName,
        userEmail1: currentUserEmail,
        userAvatar1: null, // TODO: Add photoUrl to UserModel if available
        userId2: bookOwnerId,
        userName2: bookOwnerName,
        userEmail2: bookOwnerEmail,
        userAvatar2: null, // TODO: Add photoUrl to UserModel if available
        bookId: bookId,
        bookTitle: bookTitle,
        bookImageUrl: bookImageUrl,
      );

      state = const AsyncValue.data(null);

      // Invalidate user chats to refresh
      _ref.invalidate(userChatsProvider(currentUserId));
      _ref.invalidate(userChatsProvider(bookOwnerId));

      return chatId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Sends a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required String recipientId,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _chatRepository.sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        recipientId: recipientId,
      );

      state = const AsyncValue.data(null);

      // Invalidate user chats to refresh
      _ref.invalidate(userChatsProvider(senderId));
      _ref.invalidate(userChatsProvider(recipientId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Marks messages as read in a chat
  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    try {
      await _chatRepository.markMessagesAsRead(chatId, userId);

      // Invalidate user chats to refresh unread counts
      _ref.invalidate(userChatsProvider(userId));
    } catch (e) {
      print('[ChatNotifier] Error marking messages as read: $e');
      // Don't throw - this is not critical
    }
  }
}

/// Provider for chat messages
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>(
  (ref, chatId) {
    final repository = ref.watch(chatRepositoryProvider);
    return repository.getChatMessages(chatId);
  },
);

/// Provider for chat notifier
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
  final chatRepository = ref.watch(chatRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);
  return ChatNotifier(chatRepository, userRepository, ref);
});

/// Provider for total unread message count across all chats
final totalUnreadCountProvider = StreamProvider.family<int, String>(
  (ref, userId) {
    final chatsAsync = ref.watch(userChatsProvider(userId));
    return chatsAsync.when(
      data: (chats) {
        // Calculate total unread count from all chats
        final totalUnread = chats.fold<int>(
          0,
          (sum, chat) => sum + chat.getUnreadCount(userId),
        );
        return Stream.value(totalUnread);
      },
      loading: () => Stream.value(0),
      error: (error, stackTrace) => Stream.value(0),
    );
  },
);

