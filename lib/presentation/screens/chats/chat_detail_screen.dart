import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/chat_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

/// Chat detail screen showing conversation with another user
/// 
/// Displays messages in a chat interface with proper styling
/// matching the dark theme design
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String otherUserId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.otherUserId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Mark messages as read when opening chat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = await currentUserAsync.value;
      if (currentUser != null) {
        final chatNotifier = ref.read(chatNotifierProvider.notifier);
        await chatNotifier.markMessagesAsRead(
          chatId: widget.chatId,
          userId: currentUser.uid,
        );
      }
      
      // Auto-scroll to bottom after frame is built
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to bottom of message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Handle sending a message
  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = await currentUserAsync.value;

    if (currentUser == null) {
      SnackbarUtils.showErrorSnackbar(
        context,
        'Please sign in to send messages',
      );
      return;
    }

    // Get current user name
    final currentUserName = currentUser.displayName ?? 'User';

    // Clear input immediately for better UX
    _messageController.clear();

    try {
      final chatNotifier = ref.read(chatNotifierProvider.notifier);
      await chatNotifier.sendMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUserName,
        text: text,
        recipientId: widget.otherUserId,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Restore message text on error
      _messageController.text = text;
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Failed to send message: ${e.toString()}',
        );
      }
    }
  }

  /// Check if message is from current user
  bool _isCurrentUser(String senderId, String? currentUserId) {
    if (currentUserId == null) return false;
    return senderId == currentUserId;
  }

  /// Group messages by date
  Map<String, List<MessageModel>> _groupMessagesByDate(List<MessageModel> messages) {
    final Map<String, List<MessageModel>> grouped = {};
    
    for (final message in messages) {
      final dateKey = DateFormat('MMMM d').format(message.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(message);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) {
          return Scaffold(
            backgroundColor: AppColors.primaryBackground,
            appBar: AppBar(
              backgroundColor: AppColors.primaryBackground,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.accent),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Text(
                'Please sign in to view chat',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return messagesAsync.when(
          data: (messages) {
            final groupedMessages = _groupMessagesByDate(messages);
            
            return _buildChatUI(currentUser.uid, messages, groupedMessages);
          },
          loading: () => _buildScaffoldWithAppBar(
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              ),
            ),
          ),
          error: (error, stackTrace) => _buildScaffoldWithAppBar(
            body: Center(
              child: Text(
                'Error loading messages: ${error.toString()}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        );
      },
      loading: () => _buildScaffoldWithAppBar(
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
      ),
      error: (error, stackTrace) => _buildScaffoldWithAppBar(
        body: Center(
          child: Text(
            'Error: ${error.toString()}',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.accent,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.otherUserName,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.textPrimary,
          ),
          color: AppColors.cardBackground,
          onSelected: (value) {
            if (value == 'block') {
              SnackbarUtils.showInfoSnackbar(
                context,
                'Block feature coming soon',
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'block',
              child: Text(
                'Block User',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScaffoldWithAppBar({required Widget body}) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(),
      body: body,
    );
  }

  Widget _buildChatUI(String currentUserId, List<MessageModel> messages, Map<String, List<MessageModel>> groupedMessages) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    itemCount: groupedMessages.length * 2, // Date headers + messages
                    itemBuilder: (context, index) {
                      // Calculate which date group we're in
                      final dateKeys = groupedMessages.keys.toList();
                      
                      if (index.isEven) {
                        // Date divider
                        final dateIndex = index ~/ 2;
                        if (dateIndex >= dateKeys.length) return const SizedBox.shrink();
                        
                        final dateKey = dateKeys[dateIndex];
                        return _buildDateDivider(dateKey);
                      } else {
                        // Messages for this date
                        final dateIndex = index ~/ 2;
                        if (dateIndex >= dateKeys.length) return const SizedBox.shrink();
                        
                        final dateKey = dateKeys[dateIndex];
                        final messagesForDate = groupedMessages[dateKey]!;
                        
                        return Column(
                          children: messagesForDate
                              .map((message) => _buildMessageBubble(message, currentUserId))
                              .toList(),
                        );
                      }
                    },
                  ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              'No messages yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the conversation!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, String currentUserId) {
    final isCurrentUser = _isCurrentUser(message.senderId, currentUserId);
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for received messages
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: widget.otherUserAvatar != null
                  ? ClipOval(
                      child: Image.network(
                        widget.otherUserAvatar!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          message.senderName[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryBackground,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      message.senderName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primaryBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppColors.accent
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isCurrentUser
                          ? AppColors.primaryBackground
                          : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: isCurrentUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                    // Show read/unread indicator for sent messages
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all
                            : Icons.done,
                        size: 14,
                        color: message.isRead
                            ? AppColors.accent
                            : AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'Send',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

