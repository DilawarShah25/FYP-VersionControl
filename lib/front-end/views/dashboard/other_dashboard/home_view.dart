import 'package:flutter/material.dart';
import '../../slider/carousel_view.dart';
import '../../progress/progress_details_view.dart';
import '../../detection/detection_results_view.dart'; // Import DetectionResultView

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.blue[50],
            child: Column(
              children: [
                const SizedBox(
                  height: 535.0,
                  width: double.infinity,
                  child: Carousel(
                    images: [
                      'lib/front-end/assets/images/carousel_item1.png',
                      'lib/front-end/assets/images/carousel_item2.png',
                      'lib/front-end/assets/images/carousel_item3.png',
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Early Detection\nMakes a Difference',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCard(
                          height: 350,
                          gradient: LinearGradient(
                            colors: [Colors.blue[200]!, Colors.lightBlue[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: Colors.grey.withOpacity(0.3),
                          widget: const PerformanceDetailsView(),
                        ),
                        const SizedBox(height: 20),
                        _buildCard(
                          height: 390,
                          gradient: LinearGradient(
                            colors: [Colors.lightGreen[100]!, Colors.lightGreen[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shadowColor: Colors.black.withOpacity(0.1),
                          widget: const DetectionResultView(title: 'Detection Result'),
                        ),
                        const SizedBox(height: 20),
                        _buildCard(
                          height: 190,
                          gradient: LinearGradient(
                            colors: [Colors.orange[200]!, Colors.orange[100]!],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          shadowColor: Colors.black.withOpacity(0.1),
                          widget: Center(
                            child: Text(
                              'Add your content here',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange[900],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required double height,
    required Gradient gradient,
    required Color shadowColor,
    required Widget widget,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: widget,
      ),
    );
  }
}
