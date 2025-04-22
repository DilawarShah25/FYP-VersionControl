import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../services/community_firebase_service.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;

  const ChatScreen({super.key, required this.otherUserId, this.otherUserName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final CommunityFirebaseService _service = CommunityFirebaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _displayName;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _scrollController.addListener(_scrollToBottom);
  }

  Future<void> _fetchUserName() async {
    try {
      final profile = await _service.getUserProfile(widget.otherUserId);
      if (profile != null && mounted) {
        setState(() {
          _displayName = profile.username ?? widget.otherUserName ?? 'User';
        });
      } else {
        setState(() {
          _displayName = widget.otherUserName ?? 'User';
          _errorMessage = 'Unable to load user profile';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _displayName = widget.otherUserName ?? 'User';
          _errorMessage = 'Error fetching user profile: $e';
        });
        debugPrint('Error fetching user name for user ${widget.otherUserId}: $e');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message cannot be empty', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _service.sendMessage(widget.otherUserId, text);
      _messageController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent', style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('Recipient not found')) {
        errorMsg = 'Recipient profile not found. They may have deleted their account.';
      } else if (e.toString().contains('Cannot send message to self')) {
        errorMsg = 'You cannot send a message to yourself.';
      } else if (e.toString().contains('Permission denied')) {
        errorMsg = 'Permission error: Unable to send message due to server restrictions.';
      } else if (e.toString().contains('Network error')) {
        errorMsg = 'Network error: Please check your internet connection and try again.';
      } else {
        errorMsg = 'Error sending message: $e';
      }
      setState(() => _errorMessage = errorMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Error sending message to ${widget.otherUserId}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in.', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox();
    }

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _displayName ?? 'Chat',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.white),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    color: AppTheme.errorColor,
                    padding: const EdgeInsets.all(AppTheme.paddingSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(color: AppTheme.white),
                          ),
                        ),
                        if (_errorMessage!.contains('Network error') || _errorMessage!.contains('Permission error'))
                          TextButton(
                            onPressed: _sendMessage,
                            child: Text(
                              'Retry',
                              style: GoogleFonts.poppins(color: AppTheme.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<MessageModel>>(
                    stream: _service.getMessages(widget.otherUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                      }
                      if (snapshot.hasError) {
                        debugPrint('Error fetching messages for user ${widget.otherUserId}: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(color: AppTheme.errorColor),
                          ),
                        );
                      }
                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return Center(
                          child: Text(
                            'No messages yet.',
                            style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isOwnMessage = message.senderId == user.uid;
                          return Align(
                            alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: AppTheme.paddingSmall,
                                horizontal: AppTheme.paddingMedium,
                              ),
                              padding: const EdgeInsets.all(AppTheme.paddingMedium),
                              decoration: BoxDecoration(
                                color: isOwnMessage ? AppTheme.primaryColor : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                isOwnMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.text,
                                    style: GoogleFonts.poppins(
                                      color: isOwnMessage ? AppTheme.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy, hh:mm a').format(message.timestamp.toDate()),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: isOwnMessage ? AppTheme.white.withOpacity(0.7) : Colors.black54,
                                    ),
                                  ),
                                  if (message.editedAt != null)
                                    Text(
                                      'Edited: ${DateFormat('MMM dd, yyyy, hh:mm a').format(message.editedAt!.toDate())}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: isOwnMessage ? AppTheme.white.withOpacity(0.7) : Colors.black54,
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      IconButton(
                        icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}