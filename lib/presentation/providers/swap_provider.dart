import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/swap_model.dart';
import '../../data/repositories/swap_repository.dart';

/// Provider for swap repository
final swapRepositoryProvider = Provider<SwapRepository>((ref) {
  return SwapRepository.instance;
});

/// Provider for user's swaps (sent and received)
final userSwapsProvider = StreamProvider.family<List<SwapModel>, String>(
  (ref, userId) {
    final repository = ref.watch(swapRepositoryProvider);
    return repository.getUserSwaps(userId);
  },
);

/// Provider for sent swaps
final sentSwapsProvider = StreamProvider.family<List<SwapModel>, String>(
  (ref, userId) {
    final repository = ref.watch(swapRepositoryProvider);
    return repository.getSentSwaps(userId);
  },
);

/// Provider for received swaps
final receivedSwapsProvider = StreamProvider.family<List<SwapModel>, String>(
  (ref, userId) {
    final repository = ref.watch(swapRepositoryProvider);
    return repository.getReceivedSwaps(userId);
  },
);

/// Provider for pending swaps for a specific book
final pendingSwapsForBookProvider = FutureProvider.family<List<SwapModel>, String>(
  (ref, bookId) async {
    final repository = ref.watch(swapRepositoryProvider);
    return await repository.getPendingSwapsForBook(bookId);
  },
);

/// Notifier for swap operations
class SwapNotifier extends StateNotifier<AsyncValue<void>> {
  final SwapRepository _repository;
  final Ref _ref;

  SwapNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  /// Creates a swap offer
  Future<void> createSwapOffer({
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
    state = const AsyncValue.loading();
    
    try {
      await _repository.createSwapOffer(
        bookId: bookId,
        bookTitle: bookTitle,
        bookImageUrl: bookImageUrl,
        senderId: senderId,
        senderName: senderName,
        senderEmail: senderEmail,
        recipientId: recipientId,
        recipientName: recipientName,
        recipientEmail: recipientEmail,
        message: message,
      );
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers to refresh data
      _ref.invalidate(userSwapsProvider(senderId));
      _ref.invalidate(userSwapsProvider(recipientId));
      _ref.invalidate(receivedSwapsProvider(recipientId));
      _ref.invalidate(sentSwapsProvider(senderId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Accepts a swap offer
  Future<void> acceptSwap(String swapId) async {
    state = const AsyncValue.loading();
    
    try {
      // Get swap details first
      final swap = await _repository.getSwap(swapId);
      if (swap == null) {
        throw Exception('Swap not found');
      }
      
      await _repository.acceptSwap(swapId);
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(userSwapsProvider(swap.senderId));
      _ref.invalidate(userSwapsProvider(swap.recipientId));
      _ref.invalidate(receivedSwapsProvider(swap.recipientId));
      _ref.invalidate(sentSwapsProvider(swap.senderId));
      _ref.invalidate(pendingSwapsForBookProvider(swap.bookId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Rejects a swap offer
  Future<void> rejectSwap(String swapId) async {
    state = const AsyncValue.loading();
    
    try {
      final swap = await _repository.getSwap(swapId);
      if (swap == null) {
        throw Exception('Swap not found');
      }
      
      await _repository.rejectSwap(swapId);
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(userSwapsProvider(swap.senderId));
      _ref.invalidate(userSwapsProvider(swap.recipientId));
      _ref.invalidate(receivedSwapsProvider(swap.recipientId));
      _ref.invalidate(sentSwapsProvider(swap.senderId));
      _ref.invalidate(pendingSwapsForBookProvider(swap.bookId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Cancels a swap offer
  Future<void> cancelSwap(String swapId) async {
    state = const AsyncValue.loading();
    
    try {
      final swap = await _repository.getSwap(swapId);
      if (swap == null) {
        throw Exception('Swap not found');
      }
      
      await _repository.cancelSwap(swapId);
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(userSwapsProvider(swap.senderId));
      _ref.invalidate(userSwapsProvider(swap.recipientId));
      _ref.invalidate(receivedSwapsProvider(swap.recipientId));
      _ref.invalidate(sentSwapsProvider(swap.senderId));
      _ref.invalidate(pendingSwapsForBookProvider(swap.bookId));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

/// Provider for swap notifier
final swapNotifierProvider = StateNotifierProvider<SwapNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(swapRepositoryProvider);
  return SwapNotifier(repository, ref);
});

