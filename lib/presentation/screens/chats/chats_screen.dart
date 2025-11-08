import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

/// Chats list screen showing all conversations
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Column(
      children: [
        AppBar(
          backgroundColor: AppColors.primaryBackground,
          elevation: 0,
          title: const Text(
            'Chats',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: currentUserAsync.when(
            data: (currentUser) {
              if (currentUser == null) {
                return _buildEmptyState('Please sign in to view chats');
              }

              final chatsAsync = ref.watch(userChatsProvider(currentUser.uid));

              return chatsAsync.when(
                data: (chats) {
                  if (chats.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    itemCount: chats.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border.withOpacity(0.2),
                      indent: 72,
                    ),
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final otherUserId = chat.getOtherParticipantId(currentUser.uid);
                      final otherUserName = chat.getOtherParticipantName(currentUser.uid);
                      final otherUserAvatar = chat.getOtherParticipantAvatar(currentUser.uid);
                      final unreadCount = chat.getUnreadCount(currentUser.uid);

                      return _ChatListItem(
                        chatId: chat.id,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserAvatar: otherUserAvatar,
                        lastMessage: chat.lastMessageText ?? 'No messages yet',
                        lastMessageTime: chat.lastMessageTime ?? chat.updatedAt,
                        unreadCount: unreadCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(
                                chatId: chat.id,
                                otherUserName: otherUserName,
                                otherUserAvatar: otherUserAvatar,
                                otherUserId: otherUserId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'Error loading chats: ${error.toString()}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
            error: (error, stackTrace) => Center(
              child: Text(
                'Error loading user: ${error.toString()}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState([String? message]) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No chats yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Start swapping books to begin chatting!',
              style: const TextStyle(
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

class _ChatListItem extends StatelessWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.onTap,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      final hour = time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.month}/${time.day}/${time.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.accent,
                child: otherUserAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          otherUserAvatar!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            otherUserName[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primaryBackground,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryBackground,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          otherUserName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.primaryBackground,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
