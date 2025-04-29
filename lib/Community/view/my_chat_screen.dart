import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_theme.dart';

class MyChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const MyChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _MyChatScreenState createState() => _MyChatScreenState();
}

class _MyChatScreenState extends State<MyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  late Stream<QuerySnapshot> _messagesStream;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId == null) {
      Navigator.of(context).pop();
      return;
    }
    _messagesStream = _firestore
        .collection('chats')
        .doc(_getChatId(_currentUserId!, widget.recipientId))
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }

  Future<void> _sendMessage({String? text, String? imageBase64}) async {
    if (_currentUserId == null || (text?.isEmpty ?? true) && imageBase64 == null) return;

    final message = {
      'senderId': _currentUserId,
      'recipientId': widget.recipientId,
      'text': text ?? '',
      'imageBase64': imageBase64,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection('chats')
          .doc(_getChatId(_currentUserId!, widget.recipientId))
          .collection('messages')
          .add(message);
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final bytes = await image.readAsBytes();
      if (bytes.length > 1 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image size exceeds 1MB limit', style: Theme.of(context).textTheme.bodyMedium),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      final imageBase64 = base64Encode(bytes);
      await _sendMessage(imageBase64: imageBase64);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process image: $e', style: Theme.of(context).textTheme.bodyMedium),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                widget.recipientName,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.white,
                ),
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              elevation: 0,
              iconTheme: const IconThemeData(
                color: AppTheme.white, // Set back button to white
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!.docs;
                      String? lastDate;

                      return ListView.builder(
                        reverse: true,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index].data() as Map<String, dynamic>;
                          final timestamp = message['timestamp'] as Timestamp?;
                          final currentDate = _formatTimestamp(timestamp);
                          final isSender = message['senderId'] == _currentUserId;
                          final showDateHeader = lastDate != currentDate;

                          lastDate = currentDate;

                          return Column(
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSmall),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.paddingMedium,
                                        vertical: AppTheme.paddingSmall,
                                      ),
                                      child: Text(
                                        currentDate,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(message, isSender),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSender) {
    final text = message['text'] as String?;
    final imageBase64 = message['imageBase64'] as String?;
    final timestamp = message['timestamp'] as Timestamp?;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppTheme.paddingSmall,
          horizontal: AppTheme.paddingMedium,
        ),
        decoration: isSender
            ? BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        )
            : AppTheme.cardDecoration,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (imageBase64 != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(imageBase64),
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Failed to load image',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              if (text != null && text.isNotEmpty)
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSender ? AppTheme.white : Colors.black87,
                  ),
                ),
              const SizedBox(height: AppTheme.paddingSmall),
              Text(
                _formatMessageTime(timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSender ? AppTheme.white.withOpacity(0.7) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Card(
      margin: const EdgeInsets.all(AppTheme.paddingSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingSmall,
          vertical: AppTheme.paddingSmall,
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo, color: AppTheme.primaryColor),
              onPressed: _pickAndUploadImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primaryColor),
              onPressed: () => _sendMessage(text: _messageController.text.trim()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}