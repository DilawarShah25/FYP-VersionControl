import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import '../../Community/view/community_feed_screen.dart';
import '../dashboard/other_dashboard/blog/blog_view.dart';
import '../dashboard/other_dashboard/home_view.dart';
import '../../NearbyDermatologist/screens/map_screen.dart';

class Carousel extends StatefulWidget {
  final List<String> images;
  const Carousel({
    super.key,
    required this.images,
  });

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _gradientColor1 = ColorTween(
      begin: const Color(0xFF004D6D),
      end: const Color(0xFF00BFA5),
    ).animate(_animationController);
    _gradientColor2 = ColorTween(
      begin: const Color(0xFFE0F2F1),
      end: const Color(0xFF4CAF50),
    ).animate(_animationController);
    _startAutoSlide();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _navigateToPage(BuildContext context, int index) async {
    switch (index) {
      case 0:
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BlogView()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityFeedScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
        break;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 550,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gradientColor1.value!,
                  _gradientColor2.value!,
                  _gradientColor1.value!.withOpacity(0.5),
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SCALP\nSENSE',
                      textAlign: TextAlign.start,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 30.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 5,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    itemBuilder: (context, index) {
                      bool isActive = index == _currentPage;
                      return GestureDetector(
                        onTap: () => _navigateToPage(context, index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.cyanAccent.withOpacity(0.7)
                                        : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  gradient: LinearGradient(
                                    colors: isActive
                                        ? [
                                      Colors.white.withOpacity(0.1),
                                      Colors.cyanAccent.withOpacity(0.2),
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
                                      color: Colors.cyanAccent.withOpacity(0.5),
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: _currentPage == index ? 12 : 8,
                      width: _currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(0.3),
                        boxShadow: _currentPage == index
                            ? [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                            : [],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
