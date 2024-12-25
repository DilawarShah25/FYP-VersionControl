import 'dart:io';
import 'package:flutter/material.dart';
import 'community_support_model.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = message.isCurrentUser;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.lightGreen[200] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      message.userName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                if (!isCurrentUser) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: isCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          _formatDate(message.time),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      if (message.imageUrls != null && message.imageUrls!.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: message.imageUrls!
                              .map((url) => url.startsWith('http')
                              ? Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Image.file(
                            File(url),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ))
                              .toList(),
                        ),
                      if (message.message.isNotEmpty) const SizedBox(height: 8),
                      if (message.message.isNotEmpty)
                        Text(
                          message.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatTimestamp(message.time),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hours = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minutes = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hours:$minutes $ampm';
  }

  String _formatDate(DateTime timestamp) {
    final day = timestamp.day;
    final month = _getMonthName(timestamp.month);
    final year = timestamp.year;
    final suffix = _getDaySuffix(day);
    return '$month $day$suffix, $year';
  }

  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
