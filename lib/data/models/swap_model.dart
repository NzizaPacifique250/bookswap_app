import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the status of a swap request
enum SwapStatus {
  pending,
  accepted,
  rejected,
  cancelled;

  /// Converts enum to Firestore string value
  String toFirestoreValue() {
    switch (this) {
      case SwapStatus.pending:
        return 'pending';
      case SwapStatus.accepted:
        return 'accepted';
      case SwapStatus.rejected:
        return 'rejected';
      case SwapStatus.cancelled:
        return 'cancelled';
    }
  }

  /// Creates enum from Firestore string value
  static SwapStatus fromFirestoreValue(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return SwapStatus.pending;
      case 'accepted':
        return SwapStatus.accepted;
      case 'rejected':
        return SwapStatus.rejected;
      case 'cancelled':
        return SwapStatus.cancelled;
      default:
        throw ArgumentError('Invalid swap status: $value');
    }
  }

  /// Returns display text for the status
  String toDisplayText() {
    switch (this) {
      case SwapStatus.pending:
        return 'Pending';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.rejected:
        return 'Rejected';
      case SwapStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Returns color code for the status
  /// Uses hex color strings for consistency
  String toColor() {
    switch (this) {
      case SwapStatus.pending:
        return '#FF9800'; // Orange
      case SwapStatus.accepted:
        return '#4CAF50'; // Green
      case SwapStatus.rejected:
        return '#F44336'; // Red
      case SwapStatus.cancelled:
        return '#9E9E9E'; // Gray
    }
  }
}

/// Model representing a book swap request
/// 
/// Contains all information about a swap offer between two users.
/// Includes sender and recipient details, book info, and swap status.
/// 
/// Example:
/// ```dart
/// final swap = SwapModel(
///   id: 'swap123',
///   bookId: 'book456',
///   bookTitle: 'The Great Book',
///   bookImageUrl: 'https://example.com/book.jpg',
///   senderId: 'user123',
///   senderName: 'John Doe',
///   senderEmail: 'john@example.com',
///   recipientId: 'user456',
///   recipientName: 'Jane Smith',
///   recipientEmail: 'jane@example.com',
///   status: SwapStatus.pending,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class SwapModel {
  /// Unique identifier for the swap (UUID)
  final String id;

  /// ID of the book being requested
  final String bookId;

  /// Title of the book being requested
  final String bookTitle;

  /// Image URL of the book being requested
  final String bookImageUrl;

  /// User ID of person initiating the swap
  final String senderId;

  /// Name of the sender
  final String senderName;

  /// Email of the sender
  final String senderEmail;

  /// User ID of the book owner (recipient)
  final String recipientId;

  /// Name of the recipient
  final String recipientName;

  /// Email of the recipient
  final String recipientEmail;

  /// Current status of the swap request
  final SwapStatus status;

  /// When the swap was created
  final DateTime createdAt;

  /// When the swap was last updated
  final DateTime updatedAt;

  /// Optional message from sender
  final String? message;

  /// Creates a SwapModel instance
  /// 
  /// All parameters except [message] are required
  const SwapModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookImageUrl,
    required this.senderId,
    required this.senderName,
    required this.senderEmail,
    required this.recipientId,
    required this.recipientName,
    required this.recipientEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.message,
  });

  /// Creates a SwapModel from a Map
  /// 
  /// Used for JSON deserialization and Firestore conversion
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  /// 
  /// Example:
  /// ```dart
  /// final map = {
  ///   'id': 'swap123',
  ///   'bookId': 'book456',
  ///   'bookTitle': 'The Great Book',
  ///   // ... other fields
  /// };
  /// final swap = SwapModel.fromMap(map);
  /// ```
  factory SwapModel.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    if (map['id'] == null || (map['id'] as String).isEmpty) {
      throw ArgumentError('Swap ID is required');
    }
    if (map['bookId'] == null || (map['bookId'] as String).isEmpty) {
      throw ArgumentError('Book ID is required');
    }
    if (map['bookTitle'] == null || (map['bookTitle'] as String).isEmpty) {
      throw ArgumentError('Book title is required');
    }
    if (map['senderId'] == null || (map['senderId'] as String).isEmpty) {
      throw ArgumentError('Sender ID is required');
    }
    if (map['recipientId'] == null || (map['recipientId'] as String).isEmpty) {
      throw ArgumentError('Recipient ID is required');
    }

    return SwapModel(
      id: map['id'] as String,
      bookId: map['bookId'] as String,
      bookTitle: map['bookTitle'] as String,
      bookImageUrl: map['bookImageUrl'] as String? ?? '',
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String? ?? 'Unknown',
      senderEmail: map['senderEmail'] as String? ?? '',
      recipientId: map['recipientId'] as String,
      recipientName: map['recipientName'] as String? ?? 'Unknown',
      recipientEmail: map['recipientEmail'] as String? ?? '',
      status: SwapStatus.fromFirestoreValue(
        map['status'] as String? ?? 'pending',
      ),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] as String),
      message: map['message'] as String?,
    );
  }

  /// Converts SwapModel to a Map
  /// 
  /// Used for JSON serialization and Firestore storage
  /// 
  /// Example:
  /// ```dart
  /// final swap = SwapModel(...);
  /// final map = swap.toMap();
  /// await firestore.collection('swaps').doc(swap.id).set(map);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'bookImageUrl': bookImageUrl,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'status': status.toFirestoreValue(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'message': message,
    };
  }

  /// Creates a SwapModel from a Firestore DocumentSnapshot
  /// 
  /// Convenience method for Firestore integration
  /// 
  /// Throws [ArgumentError] if document data is invalid
  /// 
  /// Example:
  /// ```dart
  /// final doc = await firestore.collection('swaps').doc('swap123').get();
  /// final swap = SwapModel.fromFirestore(doc);
  /// ```
  factory SwapModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw ArgumentError('Document data is null for swap ${doc.id}');
    }

    // Ensure the document ID is included in the map
    if (!data.containsKey('id')) {
      data['id'] = doc.id;
    }

    return SwapModel.fromMap(data);
  }

  /// Creates a copy of this SwapModel with optional field updates
  /// 
  /// Useful for updating specific fields while preserving others
  /// 
  /// Example:
  /// ```dart
  /// final updatedSwap = swap.copyWith(
  ///   status: SwapStatus.accepted,
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  SwapModel copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? bookImageUrl,
    String? senderId,
    String? senderName,
    String? senderEmail,
    String? recipientId,
    String? recipientName,
    String? recipientEmail,
    SwapStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? message,
  }) {
    return SwapModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      bookImageUrl: bookImageUrl ?? this.bookImageUrl,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      message: message ?? this.message,
    );
  }

  /// Checks if the swap is pending
  /// 
  /// Returns true if status is pending, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isPending()) {
  ///   // Show accept/reject buttons
  /// }
  /// ```
  bool isPending() {
    return status == SwapStatus.pending;
  }

  /// Checks if the swap is accepted
  /// 
  /// Returns true if status is accepted, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isAccepted()) {
  ///   // Show success message
  /// }
  /// ```
  bool isAccepted() {
    return status == SwapStatus.accepted;
  }

  /// Checks if the swap is rejected
  /// 
  /// Returns true if status is rejected, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isRejected()) {
  ///   // Show rejection message
  /// }
  /// ```
  bool isRejected() {
    return status == SwapStatus.rejected;
  }

  /// Checks if the swap is cancelled
  /// 
  /// Returns true if status is cancelled, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isCancelled()) {
  ///   // Hide swap actions
  /// }
  /// ```
  bool isCancelled() {
    return status == SwapStatus.cancelled;
  }

  /// Returns the color code for the current status
  /// 
  /// Returns hex color code as string
  /// 
  /// Example:
  /// ```dart
  /// final color = swap.getStatusColor(); // Returns '#FF9800' for pending
  /// ```
  String getStatusColor() {
    return status.toColor();
  }

  /// Returns display text for the current status
  /// 
  /// Returns user-friendly status text
  /// 
  /// Example:
  /// ```dart
  /// final text = swap.getStatusDisplayText(); // Returns 'Pending'
  /// ```
  String getStatusDisplayText() {
    return status.toDisplayText();
  }

  /// Checks if the swap can be cancelled
  /// 
  /// Only pending swaps can be cancelled
  /// 
  /// Example:
  /// ```dart
  /// if (swap.canBeCancelled()) {
  ///   // Show cancel button
  /// }
  /// ```
  bool canBeCancelled() {
    return status == SwapStatus.pending;
  }

  /// Checks if the swap can be responded to
  /// 
  /// Only pending swaps can be accepted or rejected
  /// 
  /// Example:
  /// ```dart
  /// if (swap.canBeRespondedTo()) {
  ///   // Show accept/reject buttons
  /// }
  /// ```
  bool canBeRespondedTo() {
    return status == SwapStatus.pending;
  }

  /// Checks if this user is the sender
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isSender(currentUserId)) {
  ///   // Show "You sent a swap request" message
  /// }
  /// ```
  bool isSender(String userId) {
    return senderId == userId;
  }

  /// Checks if this user is the recipient
  /// 
  /// Example:
  /// ```dart
  /// if (swap.isRecipient(currentUserId)) {
  ///   // Show accept/reject buttons
  /// }
  /// ```
  bool isRecipient(String userId) {
    return recipientId == userId;
  }

  /// JSON serialization (for API calls)
  Map<String, dynamic> toJson() => toMap();

  /// JSON deserialization (for API calls)
  factory SwapModel.fromJson(Map<String, dynamic> json) =>
      SwapModel.fromMap(json);

  @override
  String toString() {
    return 'SwapModel('
        'id: $id, '
        'bookId: $bookId, '
        'bookTitle: $bookTitle, '
        'senderId: $senderId, '
        'recipientId: $recipientId, '
        'status: ${status.toDisplayText()}, '
        'createdAt: ${createdAt.toIso8601String()}, '
        'updatedAt: ${updatedAt.toIso8601String()}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SwapModel &&
        other.id == id &&
        other.bookId == bookId &&
        other.bookTitle == bookTitle &&
        other.bookImageUrl == bookImageUrl &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.senderEmail == senderEmail &&
        other.recipientId == recipientId &&
        other.recipientName == recipientName &&
        other.recipientEmail == recipientEmail &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.message == message;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bookId,
      bookTitle,
      bookImageUrl,
      senderId,
      senderName,
      senderEmail,
      recipientId,
      recipientName,
      recipientEmail,
      status,
      createdAt,
      updatedAt,
      message,
    );
  }
}

