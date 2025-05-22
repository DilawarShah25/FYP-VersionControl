import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';
import '../services/recommendation_service.dart';

class RecommendationsResultView extends StatefulWidget {
  final String prediction; // Kept for compatibility, not used

  const RecommendationsResultView({
    super.key,
    required this.prediction,
  });

  @override
  State<RecommendationsResultView> createState() => _RecommendationsResultViewState();
}

class _RecommendationsResultViewState extends State<RecommendationsResultView> {
  final RecommendationService _recommendationService = RecommendationService();
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _chatInputFocusNode = FocusNode();
  bool _showChat = false;
  String? _selectedCondition;
  String? _recommendation;
  bool _isLoading = false;
  bool _hasError = false;

  // List of conditions for buttons
  final List<String> _conditions = [
    'Stage 1',
    'Stage 2',
    'Stage 3',
    'Normal',
    'Invalid',
    'AlopeciaAreata',
    'AndrogeneticAlopecia',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure initial focus for accessibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _chatInputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendation(String condition) async {
    setState(() {
      _selectedCondition = condition;
      _isLoading = true;
      _hasError = false;
      _recommendation = null;
    });
    try {
      final recommendation = await _recommendationService
          .getRecommendation(condition)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Recommendation timed out. Please try again.',
      );
      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
      });
      // Provide feedback for screen readers
      SemanticsService.announce('Recommendation loaded for $condition', TextDirection.ltr);
    } catch (e) {
      setState(() {
        _recommendation = 'Error fetching recommendation: $e';
        _isLoading = false;
        _hasError = true;
      });
      SemanticsService.announce('Error loading recommendation', TextDirection.ltr);
    }
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) {
      SemanticsService.announce('Please enter a message', TextDirection.ltr);
      return;
    }

    final userMessage = _chatController.text.trim();
    setState(() {
      _chatMessages.add({'sender': 'user', 'message': userMessage});
      _chatController.clear();
    });

    // Scroll to the bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    try {
      final response = await _recommendationService
          .chatWithGemini(
        _selectedCondition ?? 'Normal',
        userMessage,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Chat response timed out. Please try again.',
      );
      setState(() {
        _chatMessages.add({'sender': 'bot', 'message': response});
      });

      // Scroll to the bottom again
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
      SemanticsService.announce('Response received: $response', TextDirection.ltr);
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'bot', 'message': 'Error: $e'});
      });
      SemanticsService.announce('Error in chat response', TextDirection.ltr);
    }
  }

  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
      if (_showChat) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(_chatInputFocusNode);
        });
      }
    });
    SemanticsService.announce(
      _showChat ? 'Chat opened' : 'Chat closed',
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme.copyWith(
        // Ensure high contrast for accessibility
        textTheme: AppTheme.theme.textTheme.apply(
          bodyColor: AppTheme.textSecondary,
          displayColor: AppTheme.primaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: AppTheme.white,
            backgroundColor: AppTheme.primaryColor,
            textStyle: AppTheme.theme.textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.paddingLarge,
              vertical: AppTheme.paddingMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Scalp Care Recommendations',
            style: AppTheme.theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w600,
            ),
            semanticsLabel: 'Scalp Care Recommendations',
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundColor,
                Color(0xFFEFF3F6),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.paddingLarge),
                          Text(
                            'Select a Scalp Condition',
                            style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                            semanticsLabel: 'Select a Scalp Condition',
                          ),
                          const SizedBox(height: AppTheme.paddingMedium),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: _conditions.length,
                            itemBuilder: (context, index) {
                              final condition = _conditions[index];
                              return _ConditionButton(
                                condition: condition,
                                onPressed: () => _fetchRecommendation(condition),
                                isSelected: _selectedCondition == condition,
                              ).animate().fadeIn(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(milliseconds: 100 * index),
                              );
                            },
                          ),
                          if (_selectedCondition != null) ...[
                            const SizedBox(height: AppTheme.paddingLarge),
                            _RecommendationCard(
                              condition: _selectedCondition!,
                              recommendation: _recommendation,
                              isLoading: _isLoading,
                              // haspurchase: true,
                              hasError: _hasError,
                              onRetry: () => _fetchRecommendation(_selectedCondition!),
                            ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                          ],
                          const SizedBox(height: AppTheme.paddingLarge),
                          _ChatToggleButton(
                            onPressed: _toggleChat,
                            isChatOpen: _showChat,
                          ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                          if (_showChat) ...[
                            const SizedBox(height: AppTheme.paddingMedium),
                            _ChatSection(
                              messages: _chatMessages,
                              scrollController: _scrollController,
                            ).animate().slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: const Duration(milliseconds: 300),
                            ),
                            const SizedBox(height: AppTheme.paddingMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showChat)
                  _ChatInput(
                    controller: _chatController,
                    onSend: _sendChatMessage,
                    focusNode: _chatInputFocusNode,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConditionButton extends StatelessWidget {
  final String condition;
  final VoidCallback onPressed;
  final bool isSelected;

  const _ConditionButton({
    required this.condition,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Select condition: $condition',
      button: true,
      selected: isSelected,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: AppTheme.white,
          backgroundColor: isSelected ? AppTheme.accentColor : AppTheme.primaryColor,
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.2),
          textStyle: AppTheme.theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          condition,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String condition;
  final String? recommendation;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const _RecommendationCard({
    required this.condition,
    required this.recommendation,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnosis: $condition',
              style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
              semanticsLabel: 'Diagnosis: $condition',
            ),
            const SizedBox(height: AppTheme.paddingMedium),
            Text(
              'Recommendation',
              style: AppTheme.theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
              semanticsLabel: 'Recommendation',
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                  strokeWidth: 2.0,
                  semanticsLabel: 'Loading recommendation',
                ),
              )
            else if (hasError)
              Column(
                children: [
                  Text(
                    recommendation ?? 'An error occurred.',
                    style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: recommendation ?? 'An error occurred.',
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                    // semanticsLabel: 'Retry recommendation',
                  ),
                ],
              )
            else
              Text(
                recommendation ?? 'No recommendation available.',
                style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                semanticsLabel: recommendation ?? 'No recommendation available.',
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatToggleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isChatOpen;

  const _ChatToggleButton({
    required this.onPressed,
    required this.isChatOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isChatOpen ? 'Close chat' : 'Open chat with AI Scalp Sense',
      button: true,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          isChatOpen ? Icons.chat_bubble_outline : Icons.chat,
          color: AppTheme.white,
        ),
        label: Text(
          isChatOpen ? 'Close Chat' : 'Chat with AI Scalp Sense',
          style: AppTheme.theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}

class _ChatSection extends StatelessWidget {
  final List<Map<String, String>> messages;
  final ScrollController scrollController;

  const _ChatSection({
    required this.messages,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat with Scalp Care Expert',
              style: AppTheme.theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
              semanticsLabel: 'Chat with Scalp Care Expert',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isUser = message['sender'] == 'user';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser)
                          const Icon(
                            Icons.support_agent,
                            color: AppTheme.primaryColor,
                            size: 20,
                            semanticLabel: 'AI assistant',
                          ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? AppTheme.accentColor
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              message['message']!,
                              style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                                color: isUser ? AppTheme.white : AppTheme.textSecondary,
                              ),
                              semanticsLabel: isUser
                                  ? 'Your message: ${message['message']}'
                                  : 'AI response: ${message['message']}',
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser)
                          const Icon(
                            Icons.person,
                            color: AppTheme.accentColor,
                            size: 20,
                            semanticLabel: 'User',
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode focusNode;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Ask AI Scalp Sense...',
                hintStyle: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                filled: true,
                fillColor: AppTheme.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium,
                  vertical: AppTheme.paddingSmall,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                ),
              ),
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              // semanticsLabel: 'Chat input',
            ),
          ),
          const SizedBox(width: AppTheme.paddingSmall),
          IconButton(
            onPressed: onSend,
            icon: const Icon(
              Icons.send,
              color: AppTheme.primaryColor,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.accentColor.withOpacity(0.2),
              padding: const EdgeInsets.all(12),
            ),
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }
}