import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/app_theme.dart';
import '../services/recommendation_service.dart';

class RecommendationsResultView extends StatefulWidget {
  final String prediction;

  const RecommendationsResultView({
    super.key,
    required this.prediction,
  });

  @override
  State<RecommendationsResultView> createState() => _RecommendationsResultViewState();
}

class _RecommendationsResultViewState extends State<RecommendationsResultView> {
  String? _recommendation;
  bool _isLoading = true;
  bool _hasError = false;
  final RecommendationService _recommendationService = RecommendationService();
  final List<Map<String, String>> _chatMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchRecommendation();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecommendation() async {
    if (widget.prediction.isEmpty) {
      setState(() {
        _recommendation = 'No prediction available.';
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final recommendation = await _recommendationService.getRecommendation(widget.prediction).timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Recommendation timed out. Please try again.',
      );
      setState(() {
        _recommendation = recommendation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recommendation = 'Error fetching recommendation: $e';
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retryRecommendation() {
    _fetchRecommendation();
  }

  Future<void> _sendChatMessage() async {
    if (_chatController.text.trim().isEmpty) return;

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
      final response = await _recommendationService.chatWithGemini(widget.prediction, userMessage).timeout(
        const Duration(seconds: 10),
        onTimeout: () => 'Chat response timed out. Please try again.',
      );
      setState(() {
        _chatMessages.add({'sender': 'bot', 'message': response});
      });

      // Scroll to the bottom again after bot response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'bot', 'message': 'Error: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Care Tips',
          style: AppTheme.theme.textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              const Color(0xFFEFF3F6),
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
                        _RecommendationCard(
                          prediction: widget.prediction,
                          recommendation: _recommendation,
                          isLoading: _isLoading,
                          hasError: _hasError,
                          onRetry: _retryRecommendation,
                        ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
                        const SizedBox(height: AppTheme.paddingLarge),
                        if (_chatMessages.isNotEmpty) ...[
                          _ChatSection(
                            messages: _chatMessages,
                            scrollController: _scrollController,
                          ),
                          const SizedBox(height: AppTheme.paddingMedium),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _ChatInput(
                controller: _chatController,
                onSend: _sendChatMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final String prediction;
  final String? recommendation;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  const _RecommendationCard({
    required this.prediction,
    required this.recommendation,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnosis: $prediction',
            style: AppTheme.theme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Text(
            'Recommendation',
            style: AppTheme.theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                strokeWidth: 2.0,
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
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(
                    'Retry',
                    style: AppTheme.theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.white,
                    ),
                  ),
                ).animate(
                  effects: [
                    ScaleEffect(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                    ),
                    ScaleEffect(
                      begin: const Offset(1.1, 1.1),
                      end: const Offset(1.0, 1.0),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      delay: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              recommendation ?? 'No recommendation available.',
              style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat with Scalp Care Expert',
            style: AppTheme.theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200, // Fixed height for chat area
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
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.accentColor : AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            message['message']!,
                            style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                              color: isUser ? AppTheme.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 8),
                      if (isUser)
                        const Icon(
                          Icons.person,
                          color: AppTheme.accentColor,
                          size: 20,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.onSend,
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
              decoration: InputDecoration(
                hintText: 'Ask about scalp care...',
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
              ),
              onSubmitted: (_) => onSend(),
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
            ),
          ),
        ],
      ),
    );
  }
}