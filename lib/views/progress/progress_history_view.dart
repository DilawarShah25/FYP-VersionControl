import 'package:flutter/material.dart';

class ProgressHistoryView extends StatefulWidget {
  const ProgressHistoryView({super.key});

  @override
  State<ProgressHistoryView> createState() => _ProgressHistoryViewState();
}

class _ProgressHistoryViewState extends State<ProgressHistoryView> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE6E0), Color(0xFFFFF3F0)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Elements
          Positioned(
            top: -30,
            left: -30,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
            ),
          ),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content Section
                Text(
                  '"Our test can help you detect hair fall early."',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Early view of hair fall is crucial for effective treatment. Learn more about our innovative solution.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Semantics(
                          label: 'Toggle Content',
                          child: ElevatedButton(
                            onPressed: _toggleExpanded,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6D00), // Orange to match HomeView
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'Show Less' : 'Read More',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AnimatedRotation(
                                  turns: _rotationAnimation.value,
                                  duration: const Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.expand_more,
                                    color: Colors.white,
                                    size: 20,
                                    semanticLabel: _isExpanded ? 'Collapse' : 'Expand',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Semantics(
                            label: 'Expanded Content',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Early Detection of Hair Fall',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Early view of hair fall is crucial for effective treatment. Scalp Sense offers an innovative solution that helps you identify the first signs of hair loss, enabling you to take action before the situation worsens.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'How It Helps:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildBulletPoint('Scalp Analysis: The app detects signs of thinning and other early indicators of hair loss.'),
                                _buildBulletPoint('Personalized Treatment Plans: Based on your condition, Scalp Sense provides early interventions to prevent further damage.'),
                                _buildBulletPoint('Proactive Care: Catching hair fall early means you can start treatments sooner, reducing the impact.'),
                                const SizedBox(height: 10),
                                const Text(
                                  'Conclusion',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'With Scalp Sense, early view of hair fall is within your reach. By addressing hair loss early, you can ensure healthier hair in the long run.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}