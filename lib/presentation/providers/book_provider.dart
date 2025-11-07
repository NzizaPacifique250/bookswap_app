import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/book_repository.dart';
import '../../data/models/book_model.dart';

/// Provider for BookRepository singleton instance
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository.instance;
});

/// StreamProvider that provides all available and pending books
/// 
/// Returns a stream of List<BookModel> that updates in real-time
/// Only includes books with status 'available' or 'pending'
/// 
/// Usage:
/// ```dart
/// final allBooks = ref.watch(allBooksProvider);
/// allBooks.when(
///   data: (books) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final allBooksProvider = StreamProvider<List<BookModel>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getAllBooks();
});

/// Family provider that provides books for a specific user
/// 
/// [userId] - Firebase Auth UID of the user
/// 
/// Returns a stream of List<BookModel> that updates in real-time
/// 
/// Usage:
/// ```dart
/// final userBooks = ref.watch(userBooksProvider('user123'));
/// ```
final userBooksProvider = StreamProvider.family<List<BookModel>, String>(
  (ref, userId) {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.getUserBooks(userId);
  },
);

/// StateProvider for search query
/// 
/// Used to filter books based on search input
/// 
/// Usage:
/// ```dart
/// ref.read(searchQueryProvider.notifier).state = 'gatsby';
/// ```
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider that filters books based on search query
/// 
/// Combines allBooksProvider with searchQueryProvider
/// Returns filtered list of books matching the search query
/// 
/// Usage:
/// ```dart
/// final filteredBooks = ref.watch(filteredBooksProvider);
/// filteredBooks.when(
///   data: (books) => ListView(...),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final filteredBooksProvider = Provider<AsyncValue<List<BookModel>>>((ref) {
  final allBooksAsync = ref.watch(allBooksProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return allBooksAsync.when(
    data: (books) {
      if (searchQuery.isEmpty) {
        return AsyncValue.data(books);
      }

      final query = searchQuery.toLowerCase();
      final filtered = books.where((book) {
        final title = book.title.toLowerCase();
        final author = book.author.toLowerCase();
        return title.contains(query) || author.contains(query);
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// StateNotifier for managing book operations
/// 
/// Handles adding, updating, deleting books, and updating book status
/// Uses AsyncValue<void> to manage loading, data, and error states
class BookNotifier extends StateNotifier<AsyncValue<void>> {
  final BookRepository _bookRepository;

  BookNotifier(this._bookRepository) : super(const AsyncValue.data(null));

  /// Adds a new book with image upload or URL
  /// 
  /// [title] - Book title
  /// [author] - Book author
  /// [condition] - Book condition (string: 'New', 'Like New', 'Good', 'Used')
  /// [imageFile] - Optional image file to upload (XFile works on both web and mobile)
  /// [imageUrl] - Optional image URL (if provided, imageFile is ignored)
  /// [ownerId] - Owner's Firebase Auth UID
  /// [ownerName] - Owner's display name
  /// [ownerEmail] - Owner's email
  /// 
  /// Either [imageFile] or [imageUrl] must be provided
  /// 
  /// Updates state to loading during operation, then to data or error
  /// 
  /// Throws exception if operation fails
  Future<void> addBook({
    required String title,
    required String author,
    required String condition,
    XFile? imageFile,
    String? imageUrl,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    try {
      print('[BookNotifier] Starting to add book: $title');
      state = const AsyncValue.loading();

      // Validate that either imageFile or imageUrl is provided
      if (imageFile == null && (imageUrl == null || imageUrl.isEmpty)) {
        throw Exception('Either image file or image URL must be provided');
      }

      // Parse condition
      final bookCondition = BookCondition.fromString(condition);

      // Create book model
      final book = BookModel(
        title: title.trim(),
        author: author.trim(),
        condition: bookCondition,
        imageUrl: imageUrl ?? '', // Will be set after image upload if using file
        ownerId: ownerId,
        ownerName: ownerName.trim(),
        ownerEmail: ownerEmail.trim(),
        status: BookStatus.available,
      );

      // Create book with image upload or URL
      await _bookRepository.createBook(book, imageFile: imageFile, imageUrl: imageUrl);

      print('[BookNotifier] Book added successfully: ${book.id}');
      state = const AsyncValue.data(null);
    } catch (e) {
      print('[BookNotifier] Error adding book: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Updates specific fields of a book
  /// 
  /// [bookId] - Book's unique identifier
  /// [updates] - Map of fields to update
  /// 
  /// Updates state to loading during operation, then to data or error
  /// 
  /// Throws exception if operation fails
  /// 
  /// Example:
  /// ```dart
  /// await bookNotifier.updateBook('book123', {
  ///   'title': 'New Title',
  ///   'condition': 'Good',
  /// });
  /// ```
  Future<void> updateBook(String bookId, Map<String, dynamic> updates) async {
    try {
      print('[BookNotifier] Starting to update book: $bookId');
      state = const AsyncValue.loading();

      // Handle condition update if present
      if (updates.containsKey('condition')) {
        final conditionString = updates['condition'] as String;
        final condition = BookCondition.fromString(conditionString);
        updates['condition'] = condition.toFirestoreValue();
      }

      // Handle status update if present
      if (updates.containsKey('status')) {
        final statusString = updates['status'] as String;
        final status = BookStatus.fromString(statusString);
        updates['status'] = status.toFirestoreValue();
      }

      await _bookRepository.updateBook(bookId, updates);

      print('[BookNotifier] Book updated successfully: $bookId');
      state = const AsyncValue.data(null);
    } catch (e) {
      print('[BookNotifier] Error updating book: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Deletes a book and its associated image
  /// 
  /// [bookId] - Book's unique identifier
  /// 
  /// Updates state to loading during operation, then to data or error
  /// 
  /// Throws exception if:
  /// - Book is in pending swap
  /// - Deletion fails
  /// 
  /// Example:
  /// ```dart
  /// await bookNotifier.deleteBook('book123');
  /// ```
  Future<void> deleteBook(String bookId) async {
    try {
      print('[BookNotifier] Starting to delete book: $bookId');
      state = const AsyncValue.loading();

      await _bookRepository.deleteBook(bookId);

      print('[BookNotifier] Book deleted successfully: $bookId');
      state = const AsyncValue.data(null);
    } catch (e) {
      print('[BookNotifier] Error deleting book: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Updates book status and optional swapId
  /// 
  /// [bookId] - Book's unique identifier
  /// [status] - New status (string: 'available', 'pending', 'swapped')
  /// [swapId] - Optional swap ID to associate with book
  /// 
  /// Updates state to loading during operation, then to data or error
  /// 
  /// Throws exception if operation fails
  /// 
  /// Example:
  /// ```dart
  /// await bookNotifier.updateBookStatus(
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
      print('[BookNotifier] Starting to update book status: $bookId to $status');
      state = const AsyncValue.loading();

      // Validate status
      BookStatus.fromString(status); // Will throw if invalid

      await _bookRepository.updateBookStatus(bookId, status, swapId: swapId);

      print('[BookNotifier] Book status updated successfully: $bookId');
      state = const AsyncValue.data(null);
    } catch (e) {
      print('[BookNotifier] Error updating book status: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Resets the notifier state
  /// 
  /// Useful for clearing error states
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// StateNotifierProvider for BookNotifier
/// 
/// Provides access to book operations throughout the app
/// 
/// Usage:
/// ```dart
/// final bookNotifier = ref.watch(bookNotifierProvider.notifier);
/// final bookState = ref.watch(bookNotifierProvider);
/// 
/// // Add book
/// await bookNotifier.addBook(...);
/// 
/// // Check state
/// bookState.when(
///   data: (_) => Text('Success'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final bookNotifierProvider =
    StateNotifierProvider<BookNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(bookRepositoryProvider);
  return BookNotifier(repository);
});

/// Provider for getting a single book by ID
/// 
/// [bookId] - Book's unique identifier
/// 
/// Returns FutureProvider<BookModel?> that provides the book or null
/// 
/// Usage:
/// ```dart
/// final bookAsync = ref.watch(bookProvider('book123'));
/// bookAsync.when(
///   data: (book) => book != null ? BookCard(book) : Text('Not found'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final bookProvider = FutureProvider.family<BookModel?, String>(
  (ref, bookId) async {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.getBook(bookId);
  },
);

/// Provider for searching books
/// 
/// [query] - Search query string
/// 
/// Returns StreamProvider<List<BookModel>> with search results
/// 
/// Usage:
/// ```dart
/// final searchResults = ref.watch(searchBooksProvider('gatsby'));
/// ```
final searchBooksProvider = StreamProvider.family<List<BookModel>, String>(
  (ref, query) {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.searchBooks(query);
  },
);

/// Provider for getting books by condition
/// 
/// [condition] - BookCondition enum value
/// 
/// Returns StreamProvider<List<BookModel>> with filtered books
/// 
/// Usage:
/// ```dart
/// final books = ref.watch(booksByConditionProvider(BookCondition.likeNew));
/// ```
final booksByConditionProvider =
    StreamProvider.family<List<BookModel>, BookCondition>(
  (ref, condition) {
    final repository = ref.watch(bookRepositoryProvider);
    return repository.getBooksByCondition(condition);
  },
);

