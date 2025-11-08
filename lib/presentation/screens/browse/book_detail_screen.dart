import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../data/models/book_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/swap_provider.dart';
import '../../providers/chat_provider.dart';
import '../chats/chat_detail_screen.dart';

/// Book detail screen showing comprehensive information about a book
/// 
/// Displays book cover, details, owner information, and action buttons
/// Handles swap requests, editing, and deletion based on ownership
class BookDetailScreen extends ConsumerStatefulWidget {
  final BookModel book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _isDeleting = false;

  /// Checks if current user is the owner of the book
  bool _isOwner(String? currentUserId) {
    return currentUserId != null && currentUserId == widget.book.ownerId;
  }

  /// Gets the color for the condition badge
  Color _getConditionColor(BookCondition condition) {
    switch (condition) {
      case BookCondition.newBook:
        return AppColors.conditionNew;
      case BookCondition.likeNew:
        return AppColors.conditionLikeNew;
      case BookCondition.good:
        return AppColors.conditionGood;
      case BookCondition.used:
        return AppColors.conditionUsed;
    }
  }

  /// Formats the timestamp to readable date
  String _formatDate(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime);
  }

  /// Formats member since date
  String _formatMemberSince(DateTime dateTime) {
    return DateFormat('MMM y').format(dateTime);
  }

  /// Handles swap request
  Future<void> _handleSwapRequest() async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    
    if (currentUser == null) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please sign in to request a swap',
      );
      return;
    }

    // Check if user is trying to swap their own book
    if (currentUser.uid == widget.book.ownerId) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'You cannot request a swap for your own book',
      );
      return;
    }

    // Check if book is available
    if (!widget.book.isAvailable()) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'This book is no longer available for swapping',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Request Swap',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are about to request a swap for this book. '
              'The owner will be notified and can accept or decline your request.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book: ${widget.book.title}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${widget.book.ownerName}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final swapNotifier = ref.read(swapNotifierProvider.notifier);
        
        // Show loading
        SnackbarUtils.showLoadingSnackbar(
          context,
          'Sending swap request...',
        );

        await swapNotifier.createSwapOffer(
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          bookImageUrl: widget.book.imageUrl,
          senderId: currentUser.uid,
          senderName: currentUser.displayName ?? 'Unknown',
          senderEmail: currentUser.email ?? '',
          recipientId: widget.book.ownerId,
          recipientName: widget.book.ownerName,
          recipientEmail: widget.book.ownerEmail,
          message: 'I would like to swap for "${widget.book.title}"',
        );

        if (mounted) {
          SnackbarUtils.hideSnackbar(context);
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Swap request sent successfully! The owner will be notified.',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.hideSnackbar(context);
          SnackbarUtils.showErrorSnackbar(
            context,
            'Failed to send swap request: ${e.toString().replaceFirst('Exception: ', '')}',
          );
        }
      }
    }
  }

  /// Handles book deletion
  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
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
        content: const Text(
          'Are you sure you want to delete this book? '
          'This action cannot be undone.',
          style: TextStyle(
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
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final bookNotifier = ref.read(bookNotifierProvider.notifier);
        await bookNotifier.deleteBook(widget.book.id);

        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Book deleted successfully',
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            e.toString().replaceFirst('Exception: ', ''),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  /// Handles navigation to edit screen
  void _handleEdit() {
    // TODO: Navigate to edit book screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => EditBookScreen(book: widget.book),
    //   ),
    // );
    SnackbarUtils.showInfoSnackbar(
      context,
      'Edit functionality coming soon!',
    );
  }

  /// Handles navigation to chat
  Future<void> _handleMessage() async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = await currentUserAsync.value;

    if (currentUser == null) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please sign in to message the book owner',
      );
      return;
    }

    // Don't allow messaging yourself
    if (currentUser.uid == widget.book.ownerId) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'You cannot message yourself',
      );
      return;
    }

    try {
      // Show loading
      SnackbarUtils.showLoadingSnackbar(
        context,
        'Opening chat...',
      );

      final chatNotifier = ref.read(chatNotifierProvider.notifier);
      final chatId = await chatNotifier.getOrCreateChatWithBookOwner(
        currentUserId: currentUser.uid,
        bookOwnerId: widget.book.ownerId,
        bookOwnerName: widget.book.ownerName,
        bookOwnerEmail: widget.book.ownerEmail,
        bookId: widget.book.id,
        bookTitle: widget.book.title,
        bookImageUrl: widget.book.imageUrl,
      );

      if (mounted) {
        SnackbarUtils.hideSnackbar(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserName: widget.book.ownerName,
              otherUserAvatar: null, // TODO: Get from user profile
              otherUserId: widget.book.ownerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.hideSnackbar(context);
        SnackbarUtils.showErrorSnackbar(
          context,
          'Failed to open chat: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  /// Handles share action
  void _handleShare() {
    // TODO: Implement share functionality
    SnackbarUtils.showInfoSnackbar(
      context,
      'Share functionality coming soon!',
    );
  }

  /// Handles report action
  void _handleReport() {
    // TODO: Implement report functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Report Book',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Report functionality will be implemented soon.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.value?.uid;
    final isOwner = _isOwner(currentUserId);
    final isAvailable = widget.book.isAvailable();
    final isPending = widget.book.status == BookStatus.pending;
    final isSwapped = widget.book.status == BookStatus.swapped;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with image
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.4,
            pinned: true,
            backgroundColor: AppColors.primaryBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (!isOwner) ...[
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _handleShare,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.flag_outlined,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _handleReport,
                ),
              ],
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: _handleEdit,
                ),
                IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.error,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                  onPressed: _isDeleting ? null : _handleDelete,
                ),
              ],
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'book_image_${widget.book.id}',
                child: widget.book.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.book.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.secondaryBackground,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.secondaryBackground,
                          child: const Icon(
                            Icons.book,
                            color: AppColors.textSecondary,
                            size: 64,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.secondaryBackground,
                        child: const Icon(
                          Icons.book,
                          color: AppColors.textSecondary,
                          size: 64,
                        ),
                      ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge (if pending or swapped)
                  if (isPending || isSwapped) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppColors.statusPending
                            : AppColors.textSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPending ? 'Swap Pending' : 'Already Swapped',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title
                  Text(
                    widget.book.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Author
                  Text(
                    widget.book.author,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Condition badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getConditionColor(widget.book.condition),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.book.condition.toDisplayString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(widget.book.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // About this book section
                  const Text(
                    'About this book',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'Condition',
                          widget.book.condition.toDisplayString(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Status',
                          widget.book.status.toDisplayString(),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Posted',
                          _formatDate(widget.book.createdAt),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Owner information card
                  const Text(
                    'Owner',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.accent,
                              child: Text(
                                widget.book.ownerName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryBackground,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.book.ownerName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Member since ${_formatMemberSince(widget.book.createdAt)}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!isOwner) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _handleMessage,
                              icon: const Icon(Icons.message),
                              label: const Text('Message'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(
                                  color: AppColors.accent,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !isOwner && isAvailable
          ? FloatingActionButton.extended(
              onPressed: _handleSwapRequest,
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.primaryBackground,
              icon: const Icon(Icons.swap_horiz),
              label: const Text(
                'Request Swap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  /// Builds an info row for the about section
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

