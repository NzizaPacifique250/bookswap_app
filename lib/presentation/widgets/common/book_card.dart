import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/book_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../screens/chats/chat_detail_screen.dart';

/// Book card widget displaying book information in a card format
/// 
/// Matches the Browse Listings design with dark theme
/// Shows book cover, title, author, condition badge, and timestamp
class BookCard extends ConsumerWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
  });

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

  /// Formats the timestamp to "X days ago" format
  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Handles chat icon tap
  Future<void> _handleChatTap(BuildContext context, WidgetRef ref) async {
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
    if (currentUser.uid == book.ownerId) {
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
        bookOwnerId: book.ownerId,
        bookOwnerName: book.ownerName,
        bookOwnerEmail: book.ownerEmail,
        bookId: book.id,
        bookTitle: book.title,
        bookImageUrl: book.imageUrl,
      );

      if (context.mounted) {
        SnackbarUtils.hideSnackbar(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatId: chatId,
              otherUserName: book.ownerName,
              otherUserAvatar: null, // TODO: Get from user profile
              otherUserId: book.ownerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.hideSnackbar(context);
        SnackbarUtils.showErrorSnackbar(
          context,
          'Failed to open chat: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSwapped = book.status == BookStatus.swapped;
    final isPending = book.status == BookStatus.pending;
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUserId = currentUserAsync.value?.uid;
    final showChatIcon = currentUserId != null && currentUserId != book.ownerId;

    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isSwapped ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover image
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'book_image_${book.id}',
                          child: book.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: book.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.secondaryBackground,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
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
                                      size: 48,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppColors.secondaryBackground,
                                  child: const Icon(
                                    Icons.book,
                                    color: AppColors.textSecondary,
                                    size: 48,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    // Condition/Status badge positioned at bottom left of image
                    if (!isPending)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getConditionColor(book.condition),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.condition.toDisplayString(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Pending badge
                    if (isPending)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.statusPending,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Pending',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Chat icon positioned at top right of image (only show if not owner)
                    if (showChatIcon)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: AppColors.cardBackground.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _handleChatTap(context, ref),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 20,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  book.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Author
                Text(
                  book.author,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Timestamp
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(book.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

