import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a chat between two users
class ChatModel {
  /// Unique identifier for the chat
  final String id;

  /// IDs of the two users in the chat (sorted alphabetically for consistency)
  final List<String> participantIds;

  /// Names of the participants (matching participantIds order)
  final List<String> participantNames;

  /// Emails of the participants (matching participantIds order)
  final List<String> participantEmails;

  /// Optional avatar URLs of the participants
  final List<String?> participantAvatars;

  /// ID of the book this chat is related to (if any)
  final String? bookId;

  /// Title of the book (if any)
  final String? bookTitle;

  /// Image URL of the book (if any)
  final String? bookImageUrl;

  /// Timestamp when the chat was created
  final DateTime createdAt;

  /// Timestamp when the chat was last updated
  final DateTime updatedAt;

  /// ID of the last message (if any)
  final String? lastMessageId;

  /// Text of the last message (if any)
  final String? lastMessageText;

  /// Timestamp of the last message (if any)
  final DateTime? lastMessageTime;

  /// ID of the sender of the last message
  final String? lastMessageSenderId;

  /// Number of unread messages for each participant
  final Map<String, int> unreadCounts;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantEmails,
    required this.participantAvatars,
    this.bookId,
    this.bookTitle,
    this.bookImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageId,
    this.lastMessageText,
    this.lastMessageTime,
    this.lastMessageSenderId,
    Map<String, int>? unreadCounts,
  }) : unreadCounts = unreadCounts ?? const {};

  /// Creates a ChatModel from a Map
  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] as String,
      participantIds: List<String>.from(map['participantIds'] as List),
      participantNames: List<String>.from(map['participantNames'] as List),
      participantEmails: List<String>.from(map['participantEmails'] as List),
      participantAvatars: (map['participantAvatars'] as List?)
              ?.map((e) => e as String?)
              .toList() ??
          [],
      bookId: map['bookId'] as String?,
      bookTitle: map['bookTitle'] as String?,
      bookImageUrl: map['bookImageUrl'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
      lastMessageId: map['lastMessageId'] as String?,
      lastMessageText: map['lastMessageText'] as String?,
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] is Timestamp
              ? (map['lastMessageTime'] as Timestamp).toDate()
              : DateTime.parse(map['lastMessageTime'] as String))
          : null,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
      unreadCounts: map['unreadCounts'] != null
          ? Map<String, int>.from(
              (map['unreadCounts'] as Map).map(
                (key, value) => MapEntry(key.toString(), value as int),
              ),
            )
          : {},
    );
  }

  /// Converts ChatModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantEmails': participantEmails,
      'participantAvatars': participantAvatars,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookImageUrl': bookImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageId': lastMessageId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCounts': unreadCounts,
    };
  }

  /// Creates a ChatModel from a Firestore DocumentSnapshot
  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw ArgumentError('Document data is null for chat ${doc.id}');
    }
    final chatData = Map<String, dynamic>.from(data);
    chatData['id'] = doc.id;
    return ChatModel.fromMap(chatData);
  }

  /// Gets the other participant's ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => participantIds.first,
    );
  }

  /// Gets the other participant's name
  String getOtherParticipantName(String currentUserId) {
    final otherIndex = participantIds.indexWhere((id) => id != currentUserId);
    if (otherIndex == -1) return participantNames.first;
    return participantNames[otherIndex];
  }

  /// Gets the other participant's avatar
  String? getOtherParticipantAvatar(String currentUserId) {
    final otherIndex = participantIds.indexWhere((id) => id != currentUserId);
    if (otherIndex == -1 || otherIndex >= participantAvatars.length) {
      return null;
    }
    return participantAvatars[otherIndex];
  }

  /// Gets unread count for a specific user
  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}

/// Model representing a message in a chat
class MessageModel {
  /// Unique identifier for the message
  final String id;

  /// ID of the chat this message belongs to
  final String chatId;

  /// ID of the user who sent the message
  final String senderId;

  /// Name of the sender
  final String senderName;

  /// Text content of the message
  final String text;

  /// Timestamp when the message was sent
  final DateTime timestamp;

  /// Whether the message has been read
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  /// Creates a MessageModel from a Map
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      chatId: map['chatId'] as String,
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  /// Converts MessageModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  /// Creates a MessageModel from a Firestore DocumentSnapshot
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw ArgumentError('Document data is null for message ${doc.id}');
    }
    final messageData = Map<String, dynamic>.from(data);
    messageData['id'] = doc.id;
    return MessageModel.fromMap(messageData);
  }

  /// Creates a copy of the message with updated fields
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

