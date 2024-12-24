import 'package:flutter/material.dart';
import 'dart:async';
import '../authentication/user_login_view.dart'; // Import additional views
import '../dashboard/other_dashboard/blog_view.dart';
import '../dashboard/other_dashboard/user_manual_view.dart';
import '../dashboard/other_dashboard/home_view.dart';
class Carousel extends StatefulWidget {
  final List<String> images;

  const Carousel({
    super.key,
    required this.images,
  });

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
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

  void _navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserManualView()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserLoginView()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FaqView()),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 550,
      child: Stack(
        children: [
          // Background Image with Reduced Transparency
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('lib/front-end/assets/images/blue background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.1),
                  BlendMode.darken,
                ),
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
          // Main Carousel Content
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SCALP \n\t\t\t\t\t\tSENSE',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'CCZoinks',  // Change the fontFamily to 'CCZoinks'
                      color: Colors.white,
                      fontSize: 30.0,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 5,
                          offset: Offset(1, 1),
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
                    return GestureDetector(
                      onTap: () => _navigateToPage(context, index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Card Background
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
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
              // Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 16 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
