import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  bool _isSending = false;
  String? _errorMessage;
  static const int _maxMessageLength = 500;

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
    _messageController.addListener(() {
      setState(() {}); // Update character count
    });
  }

  String _getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }

  Future<void> _sendMessage({String? text, String? imageBase64}) async {
    if (_currentUserId == null || (text?.isEmpty ?? true) && imageBase64 == null) {
      setState(() {
        _errorMessage = 'Please enter a message or select an image';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message or select an image'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (text != null && text.length > _maxMessageLength) {
      setState(() {
        _errorMessage = 'Message exceeds $_maxMessageLength characters';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message exceeds 500 characters'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent'),
          backgroundColor: Color(0xFFFF6D00),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send message: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (source == null) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > 1 * 1024 * 1024) {
        setState(() {
          _errorMessage = 'Image size exceeds 1MB limit';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size exceeds 1MB limit'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
        return;
      }
      final imageBase64 = base64Encode(bytes);
      await _sendMessage(imageBase64: imageBase64);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process image: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
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
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  if (_errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFD32F2F),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFD32F2F),
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFD32F2F),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Semantics(
                                  label: 'Retry Button',
                                  child: ElevatedButton(
                                    onPressed: () => setState(() {
                                      _messagesStream = _firestore
                                          .collection('chats')
                                          .doc(_getChatId(_currentUserId!, widget.recipientId))
                                          .collection('messages')
                                          .orderBy('timestamp', descending: true)
                                          .snapshots();
                                    }),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF6D00),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    child: const Text(
                                      'Retry',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
                            ),
                          );
                        }

                        final messages = snapshot.data!.docs;
                        String? lastDate;

                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        currentDate,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF757575),
                                          fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E0), Color(0xFFFFF3F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -70,
            right: -70,
            child: CircleAvatar(
              radius: 120,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF6D00), Color(0xFFFF8A50)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Back Button',
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
          Text(
            widget.recipientName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 48), // Spacer for symmetry
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isSender) {
    final text = message['text'] as String?;
    final imageBase64 = message['imageBase64'] as String?;
    final timestamp = message['timestamp'] as Timestamp?;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: isSender ? 'Sent message' : 'Received message',
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isSender
                ? const LinearGradient(
              colors: [
                Color(0xFFFF6D00),
                Color(0xFFFF8A50),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: isSender ? null : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (imageBase64 != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    label: 'Message image',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'Failed to load image',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (text != null && text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSender ? Colors.white : const Color(0xFF212121),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _formatMessageTime(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: isSender ? Colors.white.withOpacity(0.7) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                label: 'Pick Image Button',
                child: IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFFFF6D00)),
                  onPressed: _isSending ? null : _pickAndUploadImage,
                  tooltip: 'Pick Image',
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    TextField(
                      controller: _messageController,
                      maxLength: _maxMessageLength,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.fromLTRB(8, 12, 8, 24),
                        counterText: '', // Hide default counter
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF212121),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        if (!_isSending) {
                          _sendMessage(text: _messageController.text.trim());
                        }
                      },
                    ),
                    Positioned(
                      bottom: 4,
                      right: 8,
                      child: Text(
                        '${_messageController.text.length}/$_maxMessageLength',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: 'Send Message Button',
                child: IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFFF6D00)),
                  onPressed: _isSending ? null : () => _sendMessage(text: _messageController.text.trim()),
                  tooltip: 'Send',
                ),
              ),
            ],
          ),
          if (_isSending)
            const LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6D00)),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}