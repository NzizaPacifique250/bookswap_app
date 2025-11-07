import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/swap_model.dart';

/// Repository for swap-related Firestore operations
/// 
/// Handles all CRUD operations for swap requests between users.
/// Manages swap lifecycle including creation, status updates, and cancellation.
/// 
/// Uses singleton pattern for consistent access across the app.
class SwapRepository {
  SwapRepository._();
  static final SwapRepository instance = SwapRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Reference to swaps collection
  CollectionReference<Map<String, dynamic>> get _swapsCollection =>
      _firestore.collection(FirebaseConstants.swapsCollection);

  /// Reference to books collection
  CollectionReference<Map<String, dynamic>> get _booksCollection =>
      _firestore.collection(FirebaseConstants.booksCollection);

  /// Creates a new swap offer
  /// 
  /// Creates a swap document and updates the book status to 'pending'.
  /// 
  /// Returns the created swap ID
  /// 
  /// Throws [Exception] if creation fails
  /// 
  /// Example:
  /// ```dart
  /// final swapId = await SwapRepository.instance.createSwapOffer(
  ///   bookId: 'book123',
  ///   bookTitle: 'The Great Book',
  ///   bookImageUrl: 'https://...',
  ///   senderId: 'user123',
  ///   senderName: 'John Doe',
  ///   senderEmail: 'john@example.com',
  ///   recipientId: 'user456',
  ///   recipientName: 'Jane Smith',
  ///   recipientEmail: 'jane@example.com',
  ///   message: 'I would love to swap for this book!',
  /// );
  /// ```
  Future<String> createSwapOffer({
    required String bookId,
    required String bookTitle,
    required String bookImageUrl,
    required String senderId,
    required String senderName,
    required String senderEmail,
    required String recipientId,
    required String recipientName,
    required String recipientEmail,
    String? message,
  }) async {
    print('[SwapRepository] Creating swap offer for book: $bookId');

    try {
      final swapId = _uuid.v4();
      final now = DateTime.now();

      final swap = SwapModel(
        id: swapId,
        bookId: bookId,
        bookTitle: bookTitle,
        bookImageUrl: bookImageUrl,
        senderId: senderId,
        senderName: senderName,
        senderEmail: senderEmail,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        status: SwapStatus.pending,
        createdAt: now,
        updatedAt: now,
        message: message,
      );

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Create swap document
      batch.set(_swapsCollection.doc(swapId), swap.toMap());

      // Update book status to pending
      batch.update(_booksCollection.doc(bookId), {
        FirebaseConstants.statusField: 'pending',
        FirebaseConstants.updatedAtField: Timestamp.now(),
      });

      await batch.commit();

      print('[SwapRepository] Swap offer created successfully: $swapId');
      return swapId;
    } catch (e, stackTrace) {
      print('[SwapRepository] Error creating swap offer: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      throw Exception('Failed to create swap offer: $e');
    }
  }

  /// Updates the status of a swap
  /// 
  /// Updates swap status and handles related book status changes:
  /// - Accepted: Updates book status to 'swapped'
  /// - Rejected/Cancelled: Updates book status to 'available'
  /// 
  /// Throws [Exception] if update fails
  /// 
  /// Example:
  /// ```dart
  /// await SwapRepository.instance.updateSwapStatus(
  ///   'swap123',
  ///   'accepted',
  /// );
  /// ```
  Future<void> updateSwapStatus(String swapId, String status) async {
    print('[SwapRepository] Updating swap status: $swapId to $status');

    try {
      // Get the swap to access book ID
      final swapDoc = await _swapsCollection.doc(swapId).get();
      if (!swapDoc.exists) {
        throw Exception('Swap not found: $swapId');
      }

      final swapData = swapDoc.data()!;
      final bookId = swapData['bookId'] as String;

      // Determine new book status based on swap status
      String? newBookStatus;
      if (status == 'accepted') {
        newBookStatus = 'swapped';
      } else if (status == 'rejected' || status == 'cancelled') {
        newBookStatus = 'available';
      }

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Update swap status
      batch.update(_swapsCollection.doc(swapId), {
        FirebaseConstants.swapStatusField: status,
        FirebaseConstants.updatedAtField: Timestamp.now(),
      });

      // Update book status if needed
      if (newBookStatus != null) {
        batch.update(_booksCollection.doc(bookId), {
          FirebaseConstants.statusField: newBookStatus,
          FirebaseConstants.updatedAtField: Timestamp.now(),
        });
      }

      await batch.commit();

      print('[SwapRepository] Swap status updated successfully');
    } catch (e, stackTrace) {
      print('[SwapRepository] Error updating swap status: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      throw Exception('Failed to update swap status: $e');
    }
  }

  /// Cancels a swap offer
  /// 
  /// Marks the swap as cancelled and updates book status back to available.
  /// 
  /// Throws [Exception] if cancellation fails
  /// 
  /// Example:
  /// ```dart
  /// await SwapRepository.instance.cancelSwap('swap123');
  /// ```
  Future<void> cancelSwap(String swapId) async {
    print('[SwapRepository] Cancelling swap: $swapId');
    await updateSwapStatus(swapId, 'cancelled');
  }

  /// Gets all swaps for a user (sent or received)
  /// 
  /// Returns a stream of swaps where the user is either sender or recipient.
  /// Can filter by status.
  /// 
  /// [userId] - User ID to get swaps for
  /// [filterStatus] - Optional status to filter by
  /// 
  /// Returns [Stream] of [List<SwapModel>] ordered by creation date (newest first)
  /// 
  /// Example:
  /// ```dart
  /// SwapRepository.instance.getUserSwaps('user123').listen((swaps) {
  ///   print('User has ${swaps.length} swaps');
  /// });
  /// 
  /// // Filter by status
  /// SwapRepository.instance.getUserSwaps(
  ///   'user123',
  ///   filterStatus: 'pending',
  /// ).listen((swaps) {
  ///   print('User has ${swaps.length} pending swaps');
  /// });
  /// ```
  Stream<List<SwapModel>> getUserSwaps(
    String userId, {
    String? filterStatus,
  }) {
    print('[SwapRepository] Getting swaps for user: $userId');

    // Note: This requires a composite index in Firestore
    // For now, we'll fetch all swaps and filter in memory
    return _swapsCollection
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final swap = SwapModel.fromFirestore(doc);
              
              // Filter by user (sender or recipient)
              final isUserInvolved = swap.senderId == userId || 
                                    swap.recipientId == userId;
              if (!isUserInvolved) return null;
              
              // Filter by status if provided
              if (filterStatus != null && 
                  swap.status.toFirestoreValue() != filterStatus) {
                return null;
              }
              
              return swap;
            } catch (e) {
              print('[SwapRepository] Error parsing swap ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SwapModel>()
          .toList();
    });
  }

  /// Gets swaps initiated by a user
  /// 
  /// Returns a stream of swaps where the user is the sender.
  /// 
  /// Example:
  /// ```dart
  /// SwapRepository.instance.getSentSwaps('user123').listen((swaps) {
  ///   print('User sent ${swaps.length} swap requests');
  /// });
  /// ```
  Stream<List<SwapModel>> getSentSwaps(String userId) {
    print('[SwapRepository] Getting sent swaps for user: $userId');

    return _swapsCollection
        .where(FirebaseConstants.swapSenderIdField, isEqualTo: userId)
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return SwapModel.fromFirestore(doc);
            } catch (e) {
              print('[SwapRepository] Error parsing swap ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SwapModel>()
          .toList();
    });
  }

  /// Gets swap offers received by a user
  /// 
  /// Returns a stream of swaps where the user is the recipient.
  /// 
  /// Example:
  /// ```dart
  /// SwapRepository.instance.getReceivedSwaps('user123').listen((swaps) {
  ///   print('User received ${swaps.length} swap offers');
  /// });
  /// ```
  Stream<List<SwapModel>> getReceivedSwaps(String userId) {
    print('[SwapRepository] Getting received swaps for user: $userId');

    return _swapsCollection
        .where(FirebaseConstants.swapRecipientIdField, isEqualTo: userId)
        .orderBy(FirebaseConstants.createdAtField, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return SwapModel.fromFirestore(doc);
            } catch (e) {
              print('[SwapRepository] Error parsing swap ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SwapModel>()
          .toList();
    });
  }

  /// Gets a single swap by ID
  /// 
  /// Returns the swap if found, null otherwise.
  /// 
  /// Example:
  /// ```dart
  /// final swap = await SwapRepository.instance.getSwap('swap123');
  /// if (swap != null) {
  ///   print('Found swap: ${swap.bookTitle}');
  /// }
  /// ```
  Future<SwapModel?> getSwap(String swapId) async {
    print('[SwapRepository] Getting swap: $swapId');

    try {
      final doc = await _swapsCollection.doc(swapId).get();
      
      if (!doc.exists) {
        print('[SwapRepository] Swap not found: $swapId');
        return null;
      }

      return SwapModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      print('[SwapRepository] Error getting swap: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Checks if a book has any active (pending) swaps
  /// 
  /// Returns true if there are pending swaps for the book, false otherwise.
  /// 
  /// Example:
  /// ```dart
  /// final hasActiveSwaps = await SwapRepository.instance
  ///     .hasActiveSwapForBook('book123');
  /// if (hasActiveSwaps) {
  ///   print('This book has pending swap offers');
  /// }
  /// ```
  Future<bool> hasActiveSwapForBook(String bookId) async {
    print('[SwapRepository] Checking for active swaps on book: $bookId');

    try {
      final snapshot = await _swapsCollection
          .where(FirebaseConstants.swapBookIdField, isEqualTo: bookId)
          .where(FirebaseConstants.swapStatusField, isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      print('[SwapRepository] Error checking active swaps: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Gets all pending swaps for a specific book
  /// 
  /// Returns a list of pending swap offers for the book.
  /// 
  /// Example:
  /// ```dart
  /// final swaps = await SwapRepository.instance
  ///     .getPendingSwapsForBook('book123');
  /// print('Book has ${swaps.length} pending offers');
  /// ```
  Future<List<SwapModel>> getPendingSwapsForBook(String bookId) async {
    print('[SwapRepository] Getting pending swaps for book: $bookId');

    try {
      final snapshot = await _swapsCollection
          .where(FirebaseConstants.swapBookIdField, isEqualTo: bookId)
          .where(FirebaseConstants.swapStatusField, isEqualTo: 'pending')
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return SwapModel.fromFirestore(doc);
            } catch (e) {
              print('[SwapRepository] Error parsing swap ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SwapModel>()
          .toList();
    } catch (e, stackTrace) {
      print('[SwapRepository] Error getting pending swaps: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Deletes a swap
  /// 
  /// Permanently removes a swap document from Firestore.
  /// Use with caution - prefer cancelling swaps instead.
  /// 
  /// Throws [Exception] if deletion fails
  /// 
  /// Example:
  /// ```dart
  /// await SwapRepository.instance.deleteSwap('swap123');
  /// ```
  Future<void> deleteSwap(String swapId) async {
    print('[SwapRepository] Deleting swap: $swapId');

    try {
      await _swapsCollection.doc(swapId).delete();
      print('[SwapRepository] Swap deleted successfully');
    } catch (e, stackTrace) {
      print('[SwapRepository] Error deleting swap: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      throw Exception('Failed to delete swap: $e');
    }
  }

  /// Gets swap statistics for a user
  /// 
  /// Returns a map with counts of different swap statuses.
  /// 
  /// Example:
  /// ```dart
  /// final stats = await SwapRepository.instance.getUserSwapStats('user123');
  /// print('Pending: ${stats['pending']}');
  /// print('Accepted: ${stats['accepted']}');
  /// print('Rejected: ${stats['rejected']}');
  /// ```
  Future<Map<String, int>> getUserSwapStats(String userId) async {
    print('[SwapRepository] Getting swap stats for user: $userId');

    try {
      final snapshot = await _swapsCollection
          .orderBy(FirebaseConstants.createdAtField, descending: true)
          .get();

      final stats = {
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'cancelled': 0,
        'sent': 0,
        'received': 0,
      };

      for (final doc in snapshot.docs) {
        try {
          final swap = SwapModel.fromFirestore(doc);
          
          if (swap.senderId == userId || swap.recipientId == userId) {
            // Count by status
            stats[swap.status.toFirestoreValue()] = 
                (stats[swap.status.toFirestoreValue()] ?? 0) + 1;
            
            // Count sent/received
            if (swap.senderId == userId) {
              stats['sent'] = stats['sent']! + 1;
            }
            if (swap.recipientId == userId) {
              stats['received'] = stats['received']! + 1;
            }
          }
        } catch (e) {
          print('[SwapRepository] Error parsing swap ${doc.id}: $e');
        }
      }

      return stats;
    } catch (e, stackTrace) {
      print('[SwapRepository] Error getting swap stats: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      return {};
    }
  }

  /// Accepts a swap offer
  /// 
  /// Convenience method to accept a swap and update all related data.
  /// Also rejects all other pending swaps for the same book.
  /// 
  /// Throws [Exception] if acceptance fails
  /// 
  /// Example:
  /// ```dart
  /// await SwapRepository.instance.acceptSwap('swap123');
  /// ```
  Future<void> acceptSwap(String swapId) async {
    print('[SwapRepository] Accepting swap: $swapId');

    try {
      // Get the swap
      final swap = await getSwap(swapId);
      if (swap == null) {
        throw Exception('Swap not found');
      }

      // Get all other pending swaps for the same book
      final otherSwaps = await getPendingSwapsForBook(swap.bookId);

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Accept this swap
      batch.update(_swapsCollection.doc(swapId), {
        FirebaseConstants.swapStatusField: 'accepted',
        FirebaseConstants.updatedAtField: Timestamp.now(),
      });

      // Update book status to swapped
      batch.update(_booksCollection.doc(swap.bookId), {
        FirebaseConstants.statusField: 'swapped',
        FirebaseConstants.updatedAtField: Timestamp.now(),
      });

      // Reject all other pending swaps for the same book
      for (final otherSwap in otherSwaps) {
        if (otherSwap.id != swapId) {
          batch.update(_swapsCollection.doc(otherSwap.id), {
            FirebaseConstants.swapStatusField: 'rejected',
            FirebaseConstants.updatedAtField: Timestamp.now(),
          });
        }
      }

      await batch.commit();

      print('[SwapRepository] Swap accepted successfully');
    } catch (e, stackTrace) {
      print('[SwapRepository] Error accepting swap: $e');
      print('[SwapRepository] Stack trace: $stackTrace');
      throw Exception('Failed to accept swap: $e');
    }
  }

  /// Rejects a swap offer
  /// 
  /// Convenience method to reject a swap and update book status.
  /// 
  /// Throws [Exception] if rejection fails
  /// 
  /// Example:
  /// ```dart
  /// await SwapRepository.instance.rejectSwap('swap123');
  /// ```
  Future<void> rejectSwap(String swapId) async {
    print('[SwapRepository] Rejecting swap: $swapId');
    await updateSwapStatus(swapId, 'rejected');
  }
}

