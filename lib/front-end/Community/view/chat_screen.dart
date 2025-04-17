import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../controllers/community_controller.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CommunityController _controller = CommunityController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MessageModel> _cachedMessages = [];

  @override
  void initState() {
    super.initState();
    debugPrint('ChatScreen initialized with otherUserId: ${widget.otherUserId}, otherUserName: ${widget.otherUserName}');
    // Debug chats collection on initialization
    _controller.service.debugChatsCollection(otherUserId: widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('Current user in ChatScreen: ${currentUser?.uid ?? "null"}');
    if (currentUser == null) {
      debugPrint('User not authenticated, redirecting to login');
      Navigator.pushReplacementNamed(context, '/login');
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _controller.getMessages(widget.otherUserId),
                initialData: const [],
                builder: (context, snapshot) {
                  debugPrint('StreamBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

                  if (snapshot.connectionState == ConnectionState.waiting && _cachedMessages.isEmpty) {
                    debugPrint('Waiting for messages to load for user: ${currentUser.uid}, otherUser: ${widget.otherUserId}');
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.secondaryColor),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    _cachedMessages = snapshot.data!;
                    debugPrint('Received ${snapshot.data!.length} messages for user: ${currentUser.uid}, otherUser: ${widget.otherUserId}');
                    if (snapshot.data!.isEmpty) {
                      debugPrint('No messages available, prompting to start conversation');
                    }
                  }

                  if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    debugPrint('Error loading messages: $error');
                    String errorMessage = 'Error loading messages';
                    if (error.contains('permission-denied')) {
                      errorMessage = 'Unable to load messages. Try sending a message to start the conversation.';
                    } else if (error.contains('index')) {
                      errorMessage = 'Query requires an index. Contact support or check Firestore console.';
                    } else if (error.contains('Invalid message')) {
                      errorMessage = 'Invalid message data in Firestore.';
                    } else if (error.contains('No authenticated user')) {
                      errorMessage = 'Not authenticated. Please sign in again.';
                    } else if (error.contains('otherUserId cannot be empty') || error.contains('Invalid recipient ID')) {
                      errorMessage = 'Invalid user ID for chat. Please select a valid user.';
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: _cachedMessages.isEmpty
                              ? Center(
                            child: Text(
                              'No messages yet. Send a message to start the conversation!',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          )
                              : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(AppTheme.paddingMedium),
                            itemCount: _cachedMessages.length,
                            itemBuilder: (context, index) {
                              final message = _cachedMessages[index];
                              final isSentByCurrentUser = message.senderId == currentUser.uid;
                              return Align(
                                alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSentByCurrentUser
                                        ? AppTheme.primaryColor
                                        : AppTheme.accentColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isSentByCurrentUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.text,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: isSentByCurrentUser ? AppTheme.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTimestamp(message.timestamp),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: isSentByCurrentUser ? AppTheme.white.withOpacity(0.7) : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          padding: const EdgeInsets.all(AppTheme.paddingMedium),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$errorMessage\nDetails: $error',
                                style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.errorColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {});
                                  _controller.service.debugChatsCollection(otherUserId: widget.otherUserId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.secondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Retry',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: AppTheme.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final messages = _cachedMessages;
                  debugPrint('Rendering ${messages.length} messages');
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Send a message to start the conversation!',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.paddingMedium),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSentByCurrentUser = message.senderId == currentUser.uid;
                      return Align(
                        alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSentByCurrentUser
                                ? AppTheme.primaryColor
                                : AppTheme.accentColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isSentByCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: isSentByCurrentUser ? AppTheme.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(message.timestamp),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isSentByCurrentUser ? AppTheme.white.withOpacity(0.7) : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.accentColor.withOpacity(0.3),
                        prefixIcon: const Icon(Icons.message, color: AppTheme.primaryColor),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.secondaryColor, size: 28),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isNotEmpty) {
                        debugPrint('Sending message to ${widget.otherUserId}: $text');
                        try {
                          await _controller.sendMessage(widget.otherUserId, text);
                          debugPrint('Message sent successfully');
                          _messageController.clear();
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                        } catch (e) {
                          debugPrint('Error sending message: $e');
                          String errorMessage = 'Failed to send message';
                          if (e.toString().contains('permission-denied')) {
                            errorMessage = 'Permission denied. Check Firestore rules or recipient ID.';
                          } else if (e.toString().contains('empty')) {
                            errorMessage = 'Message or recipient ID cannot be empty.';
                          } else if (e.toString().contains('Invalid recipient ID')) {
                            errorMessage = 'Invalid user ID. Please select a valid user.';
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$errorMessage\nDetails: $e',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      } else {
                        debugPrint('Empty message not sent');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Message cannot be empty',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    },
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}