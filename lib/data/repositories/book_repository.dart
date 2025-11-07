import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../services/firebase_service.dart';
import '../../core/constants/firebase_constants.dart';

// No need for File import - we'll use XFile.readAsBytes() for both platforms

/// Repository for book-related Firestore and Storage operations
/// 
/// This repository handles all database operations for book documents,
/// including CRUD operations, image uploads, real-time updates, and search.
class BookRepository {
  // Private constructor
  BookRepository._();

  // Singleton instance
  static BookRepository? _instance;

  /// Get singleton instance
  static BookRepository get instance {
    _instance ??= BookRepository._();
    return _instance!;
  }

  /// Get FirebaseFirestore instance from FirebaseService
  FirebaseFirestore get _firestore => FirebaseService.instance.firestore;

  /// Get FirebaseStorage instance from FirebaseService
  FirebaseStorage get _storage => FirebaseService.instance.storage;

  /// Get reference to books collection
  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      _firestore.collection(FirebaseConstants.booksCollection);

  /// Creates a new book with image upload or URL
  /// 
  /// [book] - BookModel instance to create
  /// [imageFile] - Optional image file to upload (XFile works on both web and mobile)
  /// [imageUrl] - Optional image URL (if provided, imageFile is ignored)
  /// 
  /// Returns the created book ID
  /// 
  /// Throws exception if:
  /// - Neither imageFile nor imageUrl is provided
  /// - Image upload fails (if using imageFile)
  /// - Firestore write fails
  /// 
  /// Example:
  /// ```dart
  /// // Using file upload
  /// final book = BookModel(...);
  /// final imageFile = XFile('path/to/image.jpg');
  /// final bookId = await BookRepository.instance.createBook(book, imageFile: imageFile);
  /// 
  /// // Using image URL
  /// final bookId = await BookRepository.instance.createBook(book, imageUrl: 'https://example.com/image.jpg');
  /// ```
  Future<String> createBook(
    BookModel book, {
    XFile? imageFile,
    String? imageUrl,
  }) async {
    try {
      print('[BookRepository] Creating book: ${book.title}');

      String finalImageUrl;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Use provided image URL directly
        print('[BookRepository] Using provided image URL: $imageUrl');
        finalImageUrl = imageUrl;
      } else if (imageFile != null) {
        // Upload image to storage
        print('[BookRepository] Uploading image file to storage');
        finalImageUrl = await _uploadBookImage(
          imageFile,
          book.id,
          book.ownerId,
        );
      } else {
        throw Exception('Either imageFile or imageUrl must be provided');
      }

      // Update book with image URL
      final bookWithImage = book.copyWith(imageUrl: finalImageUrl);

      // Save to Firestore
      await _booksCollection.doc(bookWithImage.id).set(
            bookWithImage.toMap(),
          );

      print('[BookRepository] Book created successfully: ${bookWithImage.id}');
      return bookWithImage.id;
    } on FirebaseException catch (e) {
      print('[BookRepository] Error creating book: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error creating book: $e');
      rethrow;
    }
  }

  /// Gets a stream of all available and pending books
  /// 
  /// Returns [Stream] that emits [List<BookModel>] whenever books change
  /// Only includes books with status 'available' or 'pending'
  /// Ordered by createdAt descending
  /// 
  /// Example:
  /// ```dart
  /// BookRepository.instance.getAllBooks().listen((books) {
  ///   print('Found ${books.length} books');
  /// });
  /// ```
  Stream<List<BookModel>> getAllBooks() {
    print('[BookRepository] Setting up stream for all books');

    // Fallback: Fetch all books, filter and sort in memory (no index needed)
    // This works immediately without requiring any Firestore indexes
    return _booksCollection
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs
          .map((doc) {
            try {
              return BookModel.fromFirestore(doc);
            } catch (e) {
              print('[BookRepository] Error parsing book ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BookModel>()
          .toList();
      
      // Filter by status (available or pending) in memory
      final filteredBooks = books.where((book) =>
          book.status == BookStatus.available ||
          book.status == BookStatus.pending).toList();
      
      // Sort by createdAt descending in memory
      filteredBooks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredBooks;
    });
  }

  /// Gets a stream of books owned by a specific user
  /// 
  /// [userId] - Owner's Firebase Auth UID
  /// 
  /// Returns [Stream] that emits [List<BookModel>] whenever user's books change
  /// Ordered by createdAt descending
  /// 
  /// Example:
  /// ```dart
  /// BookRepository.instance.getUserBooks('user123').listen((books) {
  ///   print('User has ${books.length} books');
  /// });
  /// ```
  Stream<List<BookModel>> getUserBooks(String userId) {
    print('[BookRepository] Setting up stream for user books: $userId');

    // Fallback: Only filter by ownerId, sort in memory (no composite index needed)
    // TODO: For better performance with many books, create index:
    // Collection: books, Fields: ownerId (Ascending), createdAt (Descending)
    return _booksCollection
        .where(FirebaseConstants.ownerIdField, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs
          .map((doc) {
            try {
              return BookModel.fromFirestore(doc);
            } catch (e) {
              print('[BookRepository] Error parsing book ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BookModel>()
          .toList();
      
      // Sort in memory by createdAt descending
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return books;
    });
  }

  /// Gets a single book by ID
  /// 
  /// [bookId] - Book's unique identifier
  /// 
  /// Returns [BookModel] if found, null if not found
  /// Returns null instead of throwing for not found errors
  /// 
  /// Example:
  /// ```dart
  /// final book = await BookRepository.instance.getBook('book123');
  /// if (book != null) {
  ///   print('Book found: ${book.title}');
  /// }
  /// ```
  Future<BookModel?> getBook(String bookId) async {
    try {
      print('[BookRepository] Getting book: $bookId');

      final doc = await _booksCollection.doc(bookId).get();

      if (!doc.exists) {
        print('[BookRepository] Book not found: $bookId');
        return null;
      }

      final book = BookModel.fromFirestore(doc);
      print('[BookRepository] Book retrieved successfully: $bookId');
      return book;
    } on FirebaseException catch (e) {
      print('[BookRepository] Error getting book $bookId: ${e.code} - ${e.message}');
      if (e.code == 'not-found') {
        return null;
      }
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error getting book: $e');
      rethrow;
    }
  }

  /// Updates specific fields of a book
  /// 
  /// [bookId] - Book's unique identifier
  /// [data] - Map of fields to update
  /// 
  /// Automatically adds updatedAt timestamp
  /// Uses Firestore transaction to prevent conflicts
  /// 
  /// Throws exception if update fails
  /// 
  /// Example:
  /// ```dart
  /// await BookRepository.instance.updateBook('book123', {
  ///   'title': 'New Title',
  ///   'condition': 'Good',
  /// });
  /// ```
  Future<void> updateBook(String bookId, Map<String, dynamic> data) async {
    try {
      print('[BookRepository] Updating book: $bookId with data: $data');

      // Add updatedAt timestamp
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      // Use transaction to prevent conflicts
      await _firestore.runTransaction((transaction) async {
        final bookRef = _booksCollection.doc(bookId);
        final bookDoc = await transaction.get(bookRef);

        if (!bookDoc.exists) {
          throw Exception('Book document does not exist: $bookId');
        }

        transaction.update(bookRef, updateData);
      });

      print('[BookRepository] Book updated successfully: $bookId');
    } on FirebaseException catch (e) {
      print('[BookRepository] Error updating book $bookId: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error updating book: $e');
      rethrow;
    }
  }

  /// Updates book status and optional swapId
  /// 
  /// [bookId] - Book's unique identifier
  /// [status] - New status (must be valid BookStatus string)
  /// [swapId] - Optional swap ID to associate with book
  /// 
  /// Automatically updates updatedAt timestamp
  /// 
  /// Throws exception if update fails
  /// 
  /// Example:
  /// ```dart
  /// await BookRepository.instance.updateBookStatus(
  ///   'book123',
  ///   'pending',
  ///   swapId: 'swap456',
  /// );
  /// ```
  Future<void> updateBookStatus(
    String bookId,
    String status, {
    String? swapId,
  }) async {
    try {
      print('[BookRepository] Updating book status: $bookId to $status');

      // Validate status
      BookStatus.fromString(status); // Will throw if invalid

      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (swapId != null) {
        updateData['swapId'] = swapId;
      } else if (status == 'available') {
        // Clear swapId if status is available
        updateData['swapId'] = FieldValue.delete();
      }

      await _booksCollection.doc(bookId).update(updateData);

      print('[BookRepository] Book status updated successfully: $bookId');
    } on FirebaseException catch (e) {
      print(
        '[BookRepository] Error updating book status $bookId: '
        '${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error updating book status: $e');
      rethrow;
    }
  }

  /// Deletes a book and its associated image
  /// 
  /// [bookId] - Book's unique identifier
  /// 
  /// Checks if book can be deleted (not in pending swap)
  /// Deletes book document from Firestore
  /// Deletes associated image from Storage
  /// 
  /// Throws exception if:
  /// - Book is in pending swap
  /// - Deletion fails
  /// 
  /// Example:
  /// ```dart
  /// await BookRepository.instance.deleteBook('book123');
  /// ```
  Future<void> deleteBook(String bookId) async {
    try {
      print('[BookRepository] Deleting book: $bookId');

      // Get book first to check status and get image URL
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('Book not found: $bookId');
      }

      // Check if book can be deleted
      if (book.status == BookStatus.pending) {
        throw Exception(
          'Cannot delete book that is in a pending swap. '
          'Please cancel the swap first.',
        );
      }

      // Use batch write for atomic operation
      final batch = _firestore.batch();

      // Delete book document
      batch.delete(_booksCollection.doc(bookId));

      // Commit batch
      await batch.commit();

      // Delete image from Storage (don't fail if image deletion fails)
      try {
        if (book.imageUrl.isNotEmpty) {
          await _deleteBookImage(book.imageUrl);
        }
      } catch (e) {
        print('[BookRepository] Error deleting book image: $e');
        // Continue even if image deletion fails
      }

      print('[BookRepository] Book deleted successfully: $bookId');
    } on FirebaseException catch (e) {
      print('[BookRepository] Error deleting book $bookId: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error deleting book: $e');
      rethrow;
    }
  }

  /// Uploads book image to Firebase Storage
  /// 
  /// [imageFile] - Image file to upload (XFile works on both web and mobile)
  /// [bookId] - Book's unique identifier
  /// [userId] - Owner's Firebase Auth UID
  /// 
  /// Returns the download URL of the uploaded image
  /// 
  /// Throws exception if upload fails
  /// 
  /// Path format: book_images/{userId}/{bookId}.jpg
  /// 
  /// Handles both web (using putData) and mobile (using putFile)
  Future<String> _uploadBookImage(
    XFile imageFile,
    String bookId,
    String userId,
  ) async {
    try {
      print('[BookRepository] Uploading book image: $bookId');

      // Create storage reference
      final storageRef = _storage
          .ref()
          .child(FirebaseConstants.bookImagesPath)
          .child(userId)
          .child('$bookId.jpg');

      // Use putData for both web and mobile - XFile.readAsBytes() works on both platforms
      final bytes = await imageFile.readAsBytes();
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('[BookRepository] Book image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('[BookRepository] Error uploading book image: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error uploading book image: $e');
      rethrow;
    }
  }

  /// Deletes book image from Firebase Storage
  /// 
  /// [imageUrl] - Full URL of the image to delete
  /// 
  /// Extracts storage path from URL and deletes the file
  /// 
  /// Throws exception if deletion fails
  Future<void> _deleteBookImage(String imageUrl) async {
    try {
      print('[BookRepository] Deleting book image: $imageUrl');

      // Extract path from URL
      // Firebase Storage URLs format: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 3) {
        throw Exception('Invalid image URL format');
      }

      // Extract encoded path (between 'o' and query params)
      final encodedPath = pathSegments[pathSegments.length - 1];
      final decodedPath = Uri.decodeComponent(encodedPath);

      // Create storage reference
      final storageRef = _storage.ref().child(decodedPath);

      // Delete file
      await storageRef.delete();

      print('[BookRepository] Book image deleted successfully');
    } on FirebaseException catch (e) {
      print('[BookRepository] Error deleting book image: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('[BookRepository] Unexpected error deleting book image: $e');
      rethrow;
    }
  }

  /// Searches books by title or author
  /// 
  /// [query] - Search query string
  /// 
  /// Returns [Stream] that emits [List<BookModel>] matching the search
  /// Case-insensitive search on title and author fields
  /// Only includes available and pending books
  /// 
  /// Example:
  /// ```dart
  /// BookRepository.instance.searchBooks('gatsby').listen((books) {
  ///   print('Found ${books.length} matching books');
  /// });
  /// ```
  Stream<List<BookModel>> searchBooks(String query) {
    if (query.isEmpty) {
      // Return all books if query is empty
      return getAllBooks();
    }

    print('[BookRepository] Searching books with query: $query');

    final lowerQuery = query.toLowerCase();

    // Fallback: Fetch all books, filter and search in memory (no index needed)
    return _booksCollection
        .snapshots()
        .map((snapshot) {
      final books = snapshot.docs
          .map((doc) {
            try {
              return BookModel.fromFirestore(doc);
            } catch (e) {
              print('[BookRepository] Error parsing book ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BookModel>()
          .toList();
      
      // Filter by status and search query in memory
      final filteredBooks = books.where((book) {
        // Check status
        if (book.status != BookStatus.available &&
            book.status != BookStatus.pending) {
          return false;
        }
        
        // Check search query
        final title = book.title.toLowerCase();
        final author = book.author.toLowerCase();
        return title.contains(lowerQuery) || author.contains(lowerQuery);
      }).toList();
      
      // Sort by createdAt descending in memory
      filteredBooks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return filteredBooks;
    });
  }

  /// Gets books by condition
  /// 
  /// [condition] - BookCondition enum value
  /// 
  /// Returns [Stream] that emits [List<BookModel>] with matching condition
  /// Only includes available and pending books
  /// 
  /// Example:
  /// ```dart
  /// BookRepository.instance.getBooksByCondition(BookCondition.likeNew)
  ///   .listen((books) {
  ///     print('Found ${books.length} like new books');
  ///   });
  /// ```
  Stream<List<BookModel>> getBooksByCondition(BookCondition condition) {
    print('[BookRepository] Getting books by condition: ${condition.toDisplayString()}');

    return _booksCollection
        .where(FirebaseConstants.conditionField, isEqualTo: condition.toFirestoreValue())
        .where(
          FirebaseConstants.statusField,
          whereIn: ['available', 'pending'],
        )
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return BookModel.fromFirestore(doc);
            } catch (e) {
              print('[BookRepository] Error parsing book ${doc.id}: $e');
              return null;
            }
          })
          .whereType<BookModel>()
          .toList();
    });
  }
}

