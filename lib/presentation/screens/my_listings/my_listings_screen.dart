import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/swap_model.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swap_provider.dart';
import '../../widgets/common/book_card.dart';
import '../browse/book_detail_screen.dart';
import 'add_edit_book_screen.dart';

/// My Listings screen showing user's books and swap offers
/// 
/// Contains two tabs: My Books and My Offers
/// Allows users to manage their posted books and view swap offers
class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to tab changes to update FAB visibility
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles navigation to add book screen
  void _handleAddBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditBookScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.value?.uid;

    return Column(
      children: [
        // Custom AppBar with TabBar
        Container(
          color: AppColors.primaryBackground,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AppBar title area
                SizedBox(
                  height: kToolbarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text(
                          'My Listings',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // TabBar
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.accent,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('My Books'),
                          if (currentUserId != null) ...[
                            const SizedBox(width: 8),
                            _BookCountBadge(userId: currentUserId),
                          ],
                        ],
                      ),
                    ),
                    const Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('My Offers'),
                          SizedBox(width: 8),
                          // TODO: Add offer count badge when swap provider is ready
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: currentUserId == null
              ? const Center(
                  child: Text(
                    'Please sign in to view your listings',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      children: [
                        _MyBooksTab(userId: currentUserId),
                        _MyOffersTab(userId: currentUserId),
                      ],
                    ),
                    if (_tabController.index == 0)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _handleAddBook,
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.primaryBackground,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add Book',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tab showing user's books
class _MyBooksTab extends ConsumerWidget {
  final String userId;

  const _MyBooksTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBooksAsync = ref.watch(userBooksProvider(userId));

    return userBooksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _buildEmptyState(
            icon: Icons.book_outlined,
            title: "You haven't listed any books yet",
            subtitle: 'Tap the "Add Book" button to get started',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userBooksProvider(userId));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.accent,
          backgroundColor: AppColors.cardBackground,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return _BookCardWithActions(book: book);
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(context, error, ref),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading books',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(userBooksProvider(userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Book card with edit and delete actions
class _BookCardWithActions extends ConsumerWidget {
  final BookModel book;

  const _BookCardWithActions({required this.book});

  /// Get status badge color
  Color _getStatusColor(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return const Color(0xFF4CAF50); // Green
      case BookStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case BookStatus.swapped:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  /// Get status label
  String _getStatusLabel(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.pending:
        return 'Pending';
      case BookStatus.swapped:
        return 'Swapped';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        BookCard(
          book: book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetailScreen(book: book),
              ),
            );
          },
        ),
        // Status badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(book.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusLabel(book.status),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Action buttons overlay
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button
              Material(
                color: AppColors.cardBackground.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditBookScreen(book: book),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              Material(
                color: AppColors.cardBackground.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    final bookNotifier = ref.read(bookNotifierProvider.notifier);
                    final state = ref.read(bookNotifierProvider);
                    
                    if (state.isLoading) return;

                    showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          'Delete Book',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete "${book.title}"?\n\nThis action cannot be undone.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    ).then((confirmed) async {
                      if (confirmed == true && context.mounted) {
                        try {
                          await bookNotifier.deleteBook(book.id);
                          if (context.mounted) {
                            SnackbarUtils.showSuccessSnackbar(
                              context,
                              'Book deleted successfully',
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            SnackbarUtils.showErrorSnackbar(
                              context,
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          }
                        }
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tab showing user's swap offers (both sent and received)
class _MyOffersTab extends ConsumerWidget {
  final String userId;

  const _MyOffersTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentSwapsAsync = ref.watch(sentSwapsProvider(userId));
    final receivedSwapsAsync = ref.watch(receivedSwapsProvider(userId));

    return sentSwapsAsync.when(
      data: (sentSwaps) => receivedSwapsAsync.when(
        data: (receivedSwaps) {
          // Combine and sort by creation date (newest first)
          final allSwaps = <SwapModel>[...sentSwaps, ...receivedSwaps]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (allSwaps.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sentSwapsProvider(userId));
              ref.invalidate(receivedSwapsProvider(userId));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.accent,
            backgroundColor: AppColors.cardBackground,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allSwaps.length,
              itemBuilder: (context, index) {
                final swap = allSwaps[index];
                final isSent = swap.isSender(userId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SwapRequestCard(
                    swap: swap,
                    userId: userId,
                    isSent: isSent,
                  ),
                );
              },
            ),
          );
        },
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(context, error, ref),
      ),
      loading: () => _buildLoadingState(),
      error: (error, stackTrace) => _buildErrorState(context, error, ref),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.swap_horiz,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              "You haven't made any swap offers yet",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse books and request swaps to see them here',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildShimmerCard(),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading swap offers',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(sentSwapsProvider(userId));
                ref.invalidate(receivedSwapsProvider(userId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card widget for displaying a swap request
class _SwapRequestCard extends ConsumerWidget {
  final SwapModel swap;
  final String userId;
  final bool isSent;

  const _SwapRequestCard({
    required this.swap,
    required this.userId,
    required this.isSent,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getStatusColor() {
    switch (swap.status) {
      case SwapStatus.pending:
        return AppColors.statusPending;
      case SwapStatus.accepted:
        return AppColors.statusAccepted;
      case SwapStatus.rejected:
        return AppColors.statusRejected;
      case SwapStatus.cancelled:
        return AppColors.conditionUsed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserName = isSent ? swap.recipientName : swap.senderName;

    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to book detail or swap detail screen
          // For now, just show a snackbar
          SnackbarUtils.showInfoSnackbar(
            context,
            'Swap request details coming soon',
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tag and status
              Row(
                children: [
                  // Tag indicating sent/received
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSent
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.info.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSent ? AppColors.accent : AppColors.info,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSent ? Icons.send : Icons.inbox,
                          size: 12,
                          color: isSent ? AppColors.accent : AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSent ? 'Sent' : 'Received',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSent ? AppColors.accent : AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      swap.getStatusDisplayText(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Book info and user info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: swap.bookImageUrl.isNotEmpty
                        ? Image.network(
                            swap.bookImageUrl,
                            width: 80,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  const SizedBox(width: 16),
                  // Book and user details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book title
                        Text(
                          swap.bookTitle,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // User info
                        Row(
                          children: [
                            Icon(
                              isSent ? Icons.person_outline : Icons.person,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isSent
                                    ? 'To: $otherUserName'
                                    : 'From: $otherUserName',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(swap.createdAt),
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        // Message if available
                        if (swap.message != null && swap.message!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              swap.message!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Actions based on status and sent/received
              if (swap.status == SwapStatus.pending) ...[
                const SizedBox(height: 12),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isSent)
                      // Cancel button for sent requests
                      OutlinedButton.icon(
                        onPressed: () => _handleCancelSwap(context, ref),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      )
                    else
                      // Accept/Reject buttons for received requests
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _handleRejectSwap(context, ref),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleAcceptSwap(context, ref),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.primaryBackground,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.book,
        color: AppColors.textSecondary,
        size: 40,
      ),
    );
  }

  Future<void> _handleAcceptSwap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Accept Swap Request',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to accept the swap request for "${swap.bookTitle}"?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryBackground,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(swapNotifierProvider.notifier).acceptSwap(swap.id);
        if (context.mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Swap request accepted successfully',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }

  Future<void> _handleRejectSwap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Reject Swap Request',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to reject the swap request for "${swap.bookTitle}"?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(swapNotifierProvider.notifier).rejectSwap(swap.id);
        if (context.mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Swap request rejected',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }

  Future<void> _handleCancelSwap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Swap Request',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your swap request for "${swap.bookTitle}"?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(swapNotifierProvider.notifier).cancelSwap(swap.id);
        if (context.mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Swap request cancelled',
          );
        }
      } catch (e) {
        if (context.mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      }
    }
  }
}

/// Badge showing count of user's books
class _BookCountBadge extends ConsumerWidget {
  final String userId;

  const _BookCountBadge({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userBooksAsync = ref.watch(userBooksProvider(userId));

    return userBooksAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${books.length}',
            style: const TextStyle(
              color: AppColors.primaryBackground,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

