import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
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

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: const Text(
          'My Listings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
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
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'Please sign in to view your listings',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _MyBooksTab(userId: currentUserId),
                _MyOffersTab(userId: currentUserId),
              ],
            ),
      floatingActionButton: currentUserId != null && _tabController.index == 0
          ? FloatingActionButton.extended(
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
            )
          : null,
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

/// Tab showing user's swap offers
class _MyOffersTab extends ConsumerWidget {
  final String userId;

  const _MyOffersTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Replace with actual swap offers provider when created
    // For now, show empty state
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

