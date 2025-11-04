/// Firebase collection and storage path constants
class FirebaseConstants {
  FirebaseConstants._(); // Private constructor to prevent instantiation

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String booksCollection = 'books';
  static const String swapsCollection = 'swaps';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Storage Paths
  static const String bookImagesPath = 'book_images';
  static const String profileImagesPath = 'profile_images';

  // User Document Fields (for reference)
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String displayNameField = 'displayName';
  static const String photoUrlField = 'photoUrl';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  // Book Document Fields (for reference)
  static const String bookIdField = 'bookId';
  static const String titleField = 'title';
  static const String authorField = 'author';
  static const String isbnField = 'isbn';
  static const String conditionField = 'condition';
  static const String ownerIdField = 'ownerId';
  static const String imageUrlField = 'imageUrl';
  static const String descriptionField = 'description';
  static const String statusField = 'status';

  // Swap Document Fields (for reference)
  static const String swapIdField = 'swapId';
  static const String requesterIdField = 'requesterId';
  static const String requesterBookIdField = 'requesterBookId';
  static const String ownerBookIdField = 'ownerBookId';
  static const String swapStatusField = 'swapStatus';

  // Chat Document Fields (for reference)
  static const String chatIdField = 'chatId';
  static const String participantIdsField = 'participantIds';
  static const String lastMessageField = 'lastMessage';
  static const String lastMessageTimeField = 'lastMessageTime';

  // Message Document Fields (for reference)
  static const String messageIdField = 'messageId';
  static const String senderIdField = 'senderId';
  static const String receiverIdField = 'receiverId';
  static const String textField = 'text';
  static const String timestampField = 'timestamp';
  static const String readField = 'read';
}

