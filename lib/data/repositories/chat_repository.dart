import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/chat_model.dart';

/// Repository for chat-related Firestore operations
class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Reference to chats collection
  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection(FirebaseConstants.chatsCollection);

  /// Gets or creates a chat between two users
  /// 
  /// If a chat already exists between the two users, returns it.
  /// Otherwise, creates a new chat.
  /// 
  /// Returns the chat ID
  Future<String> getOrCreateChat({
    required String userId1,
    required String userName1,
    required String userEmail1,
    String? userAvatar1,
    required String userId2,
    required String userName2,
    required String userEmail2,
    String? userAvatar2,
    String? bookId,
    String? bookTitle,
    String? bookImageUrl,
  }) async {
    print('[ChatRepository] Getting or creating chat between $userId1 and $userId2');

    try {
      // Sort participant IDs to ensure consistent chat lookup
      final participants = [userId1, userId2]..sort();

      // Try to find existing chat
      final existingChats = await _chatsCollection
          .where('participantIds', isEqualTo: participants)
          .limit(1)
          .get();

      if (existingChats.docs.isNotEmpty) {
        final chatId = existingChats.docs.first.id;
        print('[ChatRepository] Found existing chat: $chatId');
        return chatId;
      }

      // Create new chat
      final chatId = _uuid.v4();
      final now = DateTime.now();

      final chat = ChatModel(
        id: chatId,
        participantIds: participants,
        participantNames: [
          participants[0] == userId1 ? userName1 : userName2,
          participants[1] == userId2 ? userName2 : userName1,
        ],
        participantEmails: [
          participants[0] == userId1 ? userEmail1 : userEmail2,
          participants[1] == userId2 ? userEmail2 : userEmail1,
        ],
        participantAvatars: [
          participants[0] == userId1 ? userAvatar1 : userAvatar2,
          participants[1] == userId2 ? userAvatar2 : userAvatar1,
        ],
        bookId: bookId,
        bookTitle: bookTitle,
        bookImageUrl: bookImageUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _chatsCollection.doc(chatId).set(chat.toMap());

      print('[ChatRepository] Created new chat: $chatId');
      return chatId;
    } catch (e, stackTrace) {
      print('[ChatRepository] Error getting or creating chat: $e');
      print('[ChatRepository] Stack trace: $stackTrace');
      throw Exception('Failed to get or create chat: $e');
    }
  }

  /// Gets a chat by ID
  Future<ChatModel?> getChat(String chatId) async {
    try {
      final doc = await _chatsCollection.doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      print('[ChatRepository] Error getting chat: $e');
      return null;
    }
  }

  /// Gets all chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    print('[ChatRepository] Getting chats for user: $userId');

    // Fetch all chats and filter in memory to avoid composite index requirement
    return _chatsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final chat = ChatModel.fromFirestore(doc);
              // Filter by participant
              if (!chat.participantIds.contains(userId)) return null;
              return chat;
            } catch (e) {
              print('[ChatRepository] Error parsing chat ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ChatModel>()
          .toList();
    });
  }

  /// Finds a chat between two specific users
  Future<ChatModel?> findChatBetweenUsers(String userId1, String userId2) async {
    try {
      final participants = [userId1, userId2]..sort();
      
      final chats = await _chatsCollection
          .where('participantIds', isEqualTo: participants)
          .limit(1)
          .get();

      if (chats.docs.isEmpty) return null;
      return ChatModel.fromFirestore(chats.docs.first);
    } catch (e) {
      print('[ChatRepository] Error finding chat: $e');
      return null;
    }
  }

  /// Updates chat's last message info
  Future<void> updateLastMessage({
    required String chatId,
    required String messageId,
    required String messageText,
    required String senderId,
  }) async {
    try {
      await _chatsCollection.doc(chatId).update({
        'lastMessageId': messageId,
        'lastMessageText': messageText,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('[ChatRepository] Error updating last message: $e');
    }
  }

  /// Increments unread count for a user in a chat
  Future<void> incrementUnreadCount(String chatId, String userId) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      final currentCount = chat.getUnreadCount(userId);
      final unreadCounts = Map<String, int>.from(chat.unreadCounts);
      unreadCounts[userId] = currentCount + 1;

      await _chatsCollection.doc(chatId).update({
        'unreadCounts': unreadCounts,
      });
    } catch (e) {
      print('[ChatRepository] Error incrementing unread count: $e');
    }
  }

  /// Resets unread count for a user in a chat
  Future<void> resetUnreadCount(String chatId, String userId) async {
    try {
      final chat = await getChat(chatId);
      if (chat == null) return;

      final unreadCounts = Map<String, int>.from(chat.unreadCounts);
      unreadCounts[userId] = 0;

      await _chatsCollection.doc(chatId).update({
        'unreadCounts': unreadCounts,
      });
    } catch (e) {
      print('[ChatRepository] Error resetting unread count: $e');
    }
  }

  /// Reference to messages collection
  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      _firestore.collection(FirebaseConstants.messagesCollection);

  /// Gets all messages for a chat
  /// 
  /// Fetches all messages and filters/sorts in memory to avoid composite index requirement
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    print('[ChatRepository] Getting messages for chat: $chatId');
    
    // Fetch all messages and filter/sort in memory to avoid composite index
    return _messagesCollection
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final message = MessageModel.fromFirestore(doc);
              // Filter by chatId
              if (message.chatId != chatId) return null;
              return message;
            } catch (e) {
              print('[ChatRepository] Error parsing message ${doc.id}: $e');
              return null;
            }
          })
          .whereType<MessageModel>()
          .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)); // Sort by timestamp ascending
    });
  }

  /// Sends a message in a chat
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    required String recipientId,
  }) async {
    try {
      print('[ChatRepository] Sending message in chat: $chatId');
      
      final messageId = _uuid.v4();
      final now = DateTime.now();

      // Create message
      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text.trim(),
        timestamp: now,
        isRead: false,
      );

      // Save message
      await _messagesCollection.doc(messageId).set(message.toMap());

      // Update chat's last message info
      await updateLastMessage(
        chatId: chatId,
        messageId: messageId,
        messageText: text.trim(),
        senderId: senderId,
      );

      // Increment unread count for recipient
      await incrementUnreadCount(chatId, recipientId);

      print('[ChatRepository] Message sent successfully: $messageId');
    } catch (e) {
      print('[ChatRepository] Error sending message: $e');
      rethrow;
    }
  }

  /// Marks messages as read in a chat
  /// 
  /// Fetches all messages for the chat and filters in memory to avoid composite index requirement
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      print('[ChatRepository] Marking messages as read in chat: $chatId for user: $userId');
      
      // Get all messages for this chat (filter in memory to avoid composite index)
      final allMessages = await _messagesCollection.get();
      
      // Filter messages: chatId matches, senderId != userId, isRead == false
      final unreadMessages = allMessages.docs.where((doc) {
        final data = doc.data();
        return data['chatId'] == chatId &&
               data['senderId'] != userId &&
               (data['isRead'] == false || data['isRead'] == null);
      }).toList();

      if (unreadMessages.isEmpty) {
        print('[ChatRepository] No unread messages to mark as read');
        // Still reset unread count in case it's out of sync
        await resetUnreadCount(chatId, userId);
        return;
      }

      // Batch update
      final batch = _firestore.batch();
      for (final doc in unreadMessages) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count
      await resetUnreadCount(chatId, userId);

      print('[ChatRepository] ${unreadMessages.length} messages marked as read');
    } catch (e) {
      print('[ChatRepository] Error marking messages as read: $e');
    }
  }
}

