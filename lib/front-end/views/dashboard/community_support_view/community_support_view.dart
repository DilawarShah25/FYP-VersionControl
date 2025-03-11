import 'package:flutter/material.dart';
import 'community_support_controller.dart';
import 'community_support_widgets.dart';

class CommunitySupportView extends StatefulWidget {
  const CommunitySupportView({super.key});

  @override
  _CommunitySupportViewState createState() => _CommunitySupportViewState();
}

class _CommunitySupportViewState extends State<CommunitySupportView> {
  final ChatController _chatController = ChatController();
  final TextEditingController _textController = TextEditingController();
  List<String> _selectedImages = [];

  void _handleSendMessage() {
    if (_textController.text.isNotEmpty || _selectedImages.isNotEmpty) {
      _chatController.sendMessage("CurrentUser", _textController.text, true, imageUrls: _selectedImages);
      _textController.clear();
      _selectedImages = [];
      setState(() {});
    }
  }

  void _pickImages() async {
    _selectedImages = await _chatController.pickImages();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0), // Height of the AppBar
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF004e92),
                  Color(0xFF000428),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Padding(
            padding: EdgeInsets.only(right: 50.0, top: 15.0),
            child: Center(
              child: Text(
                'Community Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        // Gradient Background for the body
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF004e92),
              Color(0xFF000428),
            ],
            // begin: Alignment.topLeft,
            // end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Second Container with Curved Top, Shadow, and ScrollView
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Chat Messages
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _chatController.messages.length,
                          itemBuilder: (context, index) {
                            final message = _chatController.messages[index];
                            return ChatMessageWidget(message: message);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: _pickImages,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _handleSendMessage,
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
