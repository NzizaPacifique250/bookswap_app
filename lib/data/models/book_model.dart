import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Enum representing the condition of a book
enum BookCondition {
  newBook,
  likeNew,
  good,
  used;

  /// Converts enum to display string
  String toDisplayString() {
    switch (this) {
      case BookCondition.newBook:
        return 'New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.used:
        return 'Used';
    }
  }

  /// Converts enum to Firestore string value
  String toFirestoreValue() {
    switch (this) {
      case BookCondition.newBook:
        return 'New';
      case BookCondition.likeNew:
        return 'Like New';
      case BookCondition.good:
        return 'Good';
      case BookCondition.used:
        return 'Used';
    }
  }

  /// Creates enum from string value
  static BookCondition fromString(String value) {
    switch (value.toLowerCase()) {
      case 'new':
        return BookCondition.newBook;
      case 'like new':
      case 'likenew':
        return BookCondition.likeNew;
      case 'good':
        return BookCondition.good;
      case 'used':
        return BookCondition.used;
      default:
        throw ArgumentError('Invalid book condition: $value');
    }
  }

  /// Returns color code for the condition
  /// Uses AppColors condition colors
  String toColor() {
    switch (this) {
      case BookCondition.newBook:
        return '#4CAF50'; // Green
      case BookCondition.likeNew:
        return '#4A9FF5'; // Blue
      case BookCondition.good:
        return '#FF9800'; // Orange
      case BookCondition.used:
        return '#9E9E9E'; // Gray
    }
  }
}

/// Enum representing the status of a book
enum BookStatus {
  available,
  pending,
  swapped;

  /// Converts enum to display string
  String toDisplayString() {
    switch (this) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.pending:
        return 'Pending';
      case BookStatus.swapped:
        return 'Swapped';
    }
  }

  /// Converts enum to Firestore string value
  String toFirestoreValue() {
    switch (this) {
      case BookStatus.available:
        return 'available';
      case BookStatus.pending:
        return 'pending';
      case BookStatus.swapped:
        return 'swapped';
    }
  }

  /// Creates enum from string value
  static BookStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return BookStatus.available;
      case 'pending':
        return BookStatus.pending;
      case 'swapped':
        return BookStatus.swapped;
      default:
        throw ArgumentError('Invalid book status: $value');
    }
  }
}

/// Book model representing a book in the BookSwapp application
/// 
/// This model handles conversion between Firestore documents and Dart objects,
/// with proper validation, enums for condition and status, and helper methods.
class BookModel {
  /// Unique identifier for the book (UUID)
  final String id;

  /// Title of the book
  final String title;

  /// Author of the book
  final String author;

  /// Condition of the book (enum)
  final BookCondition condition;

  /// URL of the book's cover image
  final String imageUrl;

  /// ID of the book owner (Firebase Auth UID)
  final String ownerId;

  /// Display name of the book owner
  final String ownerName;

  /// Email of the book owner
  final String ownerEmail;

  /// Timestamp when the book was created
  final DateTime createdAt;

  /// Timestamp when the book was last updated
  final DateTime updatedAt;

  /// Current status of the book (enum)
  final BookStatus status;

  /// Swap ID if the book is in pending or swapped status (nullable)
  final String? swapId;

  /// Creates a new BookModel instance
  /// 
  /// [id] - Unique identifier (if not provided, generates UUID)
  /// [title] - Book title
  /// [author] - Book author
  /// [condition] - Book condition enum
  /// [imageUrl] - URL of book cover image
  /// [ownerId] - Owner's Firebase Auth UID
  /// [ownerName] - Owner's display name
  /// [ownerEmail] - Owner's email
  /// [createdAt] - Creation timestamp (defaults to now)
  /// [updatedAt] - Update timestamp (defaults to now)
  /// [status] - Book status enum (defaults to available)
  /// [swapId] - Optional swap ID
  BookModel({
    String? id,
    required this.title,
    required this.author,
    required this.condition,
    required this.imageUrl,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    BookStatus? status,
    this.swapId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        status = status ?? BookStatus.available;

  /// Creates a BookModel from a Map (typically from JSON or Firestore)
  /// 
  /// [map] - Map containing book data
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  /// 
  /// Example:
  /// ```dart
  /// final book = BookModel.fromMap({
  ///   'id': '123',
  ///   'title': 'The Great Gatsby',
  ///   'author': 'F. Scott Fitzgerald',
  ///   'condition': 'Like New',
  ///   'imageUrl': 'https://...',
  ///   'ownerId': 'user123',
  ///   'ownerName': 'John Doe',
  ///   'ownerEmail': 'john@example.com',
  ///   'createdAt': Timestamp.now(),
  ///   'status': 'available',
  /// });
  /// ```
  factory BookModel.fromMap(Map<String, dynamic> map) {
    // Validate required fields
    if (map['title'] == null || map['title'].toString().isEmpty) {
      throw ArgumentError('title is required and cannot be empty');
    }
    if (map['author'] == null || map['author'].toString().isEmpty) {
      throw ArgumentError('author is required and cannot be empty');
    }
    if (map['condition'] == null) {
      throw ArgumentError('condition is required');
    }
    if (map['imageUrl'] == null || map['imageUrl'].toString().isEmpty) {
      throw ArgumentError('imageUrl is required and cannot be empty');
    }
    if (map['ownerId'] == null || map['ownerId'].toString().isEmpty) {
      throw ArgumentError('ownerId is required and cannot be empty');
    }
    if (map['ownerName'] == null || map['ownerName'].toString().isEmpty) {
      throw ArgumentError('ownerName is required and cannot be empty');
    }
    if (map['ownerEmail'] == null || map['ownerEmail'].toString().isEmpty) {
      throw ArgumentError('ownerEmail is required and cannot be empty');
    }

    // Parse condition
    final conditionString = map['condition'] as String;
    final condition = BookCondition.fromString(conditionString);

    // Parse status
    final statusString = map['status'] as String? ?? 'available';
    final status = BookStatus.fromString(statusString);

    // Parse createdAt
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is DateTime) {
      createdAt = map['createdAt'] as DateTime;
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.parse(map['createdAt'] as String);
    } else if (map['createdAt'] is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int);
    } else {
      createdAt = DateTime.now();
    }

    // Parse updatedAt
    DateTime updatedAt;
    if (map['updatedAt'] != null) {
      if (map['updatedAt'] is Timestamp) {
        updatedAt = (map['updatedAt'] as Timestamp).toDate();
      } else if (map['updatedAt'] is DateTime) {
        updatedAt = map['updatedAt'] as DateTime;
      } else if (map['updatedAt'] is String) {
        updatedAt = DateTime.parse(map['updatedAt'] as String);
      } else if (map['updatedAt'] is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] as int,
        );
      } else {
        updatedAt = createdAt;
      }
    } else {
      updatedAt = createdAt;
    }

    return BookModel(
      id: map['id'] as String? ?? map['bookId'] as String?,
      title: map['title'] as String,
      author: map['author'] as String,
      condition: condition,
      imageUrl: map['imageUrl'] as String,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      ownerEmail: map['ownerEmail'] as String,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      swapId: map['swapId'] as String?,
    );
  }

  /// Converts BookModel to a Map (for JSON serialization or Firestore)
  /// 
  /// Returns a Map with all book data, converting DateTime to Timestamp
  /// and enums to string values for Firestore compatibility
  /// 
  /// Example:
  /// ```dart
  /// final map = book.toMap();
  /// await firestore.collection('books').doc(book.id).set(map);
  /// ```
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': id, // Alias for compatibility
      'title': title,
      'author': author,
      'condition': condition.toFirestoreValue(),
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.toFirestoreValue(),
      'swapId': swapId,
    };
  }

  /// Creates a BookModel from a Firestore DocumentSnapshot
  /// 
  /// [doc] - Firestore DocumentSnapshot containing book data
  /// 
  /// Throws [ArgumentError] if required fields are missing
  /// 
  /// Example:
  /// ```dart
  /// final doc = await firestore.collection('books').doc('123').get();
  /// final book = BookModel.fromFirestore(doc);
  /// ```
  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw ArgumentError('Document data is null');
    }

    // Ensure id matches document ID
    final bookData = Map<String, dynamic>.from(data);
    bookData['id'] = doc.id;

    return BookModel.fromMap(bookData);
  }

  /// Creates a copy of this BookModel with updated fields
  /// 
  /// All parameters are optional. Only provided parameters will be updated.
  /// 
  /// Returns a new BookModel instance with the updated values
  /// 
  /// Example:
  /// ```dart
  /// final updatedBook = book.copyWith(
  ///   status: BookStatus.pending,
  ///   swapId: 'swap123',
  /// );
  /// ```
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    BookCondition? condition,
    String? imageUrl,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    BookStatus? status,
    String? swapId,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      swapId: swapId ?? this.swapId,
    );
  }

  /// Returns the color code for the book's condition
  /// 
  /// Returns hex color code as string
  /// 
  /// Example:
  /// ```dart
  /// final color = book.getConditionColor(); // Returns '#4CAF50' for New
  /// ```
  String getConditionColor() {
    return condition.toColor();
  }

  /// Checks if the book is available for swapping
  /// 
  /// Returns true if status is 'available', false otherwise
  /// 
  /// Example:
  /// ```dart
  /// if (book.isAvailable()) {
  ///   // Show swap button
  /// }
  /// ```
  bool isAvailable() {
    return status == BookStatus.available;
  }

  @override
  String toString() {
    return 'BookModel('
        'id: $id, '
        'title: $title, '
        'author: $author, '
        'condition: ${condition.toDisplayString()}, '
        'imageUrl: $imageUrl, '
        'ownerId: $ownerId, '
        'ownerName: $ownerName, '
        'ownerEmail: $ownerEmail, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'status: ${status.toDisplayString()}, '
        'swapId: $swapId'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BookModel &&
        other.id == id &&
        other.title == title &&
        other.author == author &&
        other.condition == condition &&
        other.imageUrl == imageUrl &&
        other.ownerId == ownerId &&
        other.ownerName == ownerName &&
        other.ownerEmail == ownerEmail &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.status == status &&
        other.swapId == swapId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        author.hashCode ^
        condition.hashCode ^
        imageUrl.hashCode ^
        ownerId.hashCode ^
        ownerName.hashCode ^
        ownerEmail.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        status.hashCode ^
        (swapId?.hashCode ?? 0);
  }
}

