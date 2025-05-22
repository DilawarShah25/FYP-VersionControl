import 'package:flutter/material.dart';
import 'dart:async';
import '../../Community/view/community_feed_screen.dart';
import '../../NearbyDermatologist/screens/map_screen.dart';
import '../dashboard/blog/blog_view.dart';
import '../dashboard/home_view.dart';

class Carousel extends StatefulWidget {
  final List<String> images;
  const Carousel({
    super.key,
    required this.images,
  });

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _fadeController;
  late AnimationController _gradientController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _gradientController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    _gradientColor1 = ColorTween(
      begin: const Color(0xFF004D6D),
      end: const Color(0xFF00BFA5),
    ).animate(_gradientController);
    _gradientColor2 = ColorTween(
      begin: const Color(0xFFE0F2F1),
      end: const Color(0xFF4CAF50),
    ).animate(_gradientController);
    _gradientController.repeat(reverse: true);
    _startAutoSlide();
    _pageController.addListener(() {
      int newPage = _pageController.page?.round() ?? 0;
      if (_currentPage != newPage) {
        setState(() {
          _currentPage = newPage;
          _fadeController.reset();
          _fadeController.forward();
        });
      }
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isUserInteracting && _pageController.hasClients && mounted) {
        int nextPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoSlide() {
    setState(() {
      _isUserInteracting = true;
    });
    _timer.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
          _startAutoSlide();
        });
      }
    });
  }

  Future<void> _navigateToPage(BuildContext context, int index) async {
    try {
      switch (index) {
        case 0:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BlogView()),
          );
          break;
        case 1:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
          );
          break;
        case 2:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
          break;
        default:
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating: $e'),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.removeListener(() {});
    _pageController.dispose();
    _fadeController.stop();
    _fadeController.dispose();
    _gradientController.stop();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Semantics(
        label: 'Empty Carousel',
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              height: 550,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientColor1.value ?? const Color(0xFF004D6D),
                    _gradientColor2.value ?? const Color(0xFFE0F2F1),
                    (_gradientColor1.value ?? const Color(0xFF004D6D)).withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const Center(
            child: Text(
              'No images available',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'Image Carousel',
      child: SizedBox(
        height: 550,
        child: AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientColor1.value ?? const Color(0xFF004D6D),
                    _gradientColor2.value ?? const Color(0xFFE0F2F1),
                    (_gradientColor1.value ?? const Color(0xFF004D6D)).withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Stack(
            children: [
              Positioned(
                top: -50,
                left: -50,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -60,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: const Color(0xFFFFD6CC).withOpacity(0.5),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Semantics(
                          label: 'Carousel Title',
                          child: const Text(
                            'SCALP SENSE',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onPanDown: (_) => _pauseAutoSlide(),
                      onTapDown: (_) => _pauseAutoSlide(),
                      child: Semantics(
                        label: 'Swipe to navigate',
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: widget.images.length,
                          itemBuilder: (context, index) {
                            bool isActive = index == _currentPage;
                            return GestureDetector(
                              onTap: () {
                                _pauseAutoSlide();
                                _navigateToPage(context, index);
                              },
                              child: Semantics(
                                label: 'Carousel Image $index',
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: isActive ? 1.05 : 1.0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            border: Border.all(
                                              color: isActive
                                                  ? Colors.white.withOpacity(0.7)
                                                  : Colors.white.withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            gradient: LinearGradient(
                                              colors: isActive
                                                  ? [
                                                Colors.white.withOpacity(0.1),
                                                Colors.white.withOpacity(0.2),
                                              ]
                                                  : [
                                                Colors.white.withOpacity(0.05),
                                                Colors.black.withOpacity(0.1),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: isActive
                                                ? [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(0.5),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                              const BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(0, 4),
                                              ),
                                            ]
                                                : [
                                              const BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          width: 260,
                                          height: 400,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: Image.asset(
                                              widget.images[index],
                                              fit: BoxFit.cover,
                                              width: 260,
                                              height: 400,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.error,
                                                    color: Color(0xFFD32F2F),
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.images.length,
                          (index) => Semantics(
                        label: 'Page Indicator $index',
                        child: AnimatedScale(
                          scale: _currentPage == index ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: _currentPage == index ? 12 : 8,
                            width: _currentPage == index ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              boxShadow: _currentPage == index
                                  ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}