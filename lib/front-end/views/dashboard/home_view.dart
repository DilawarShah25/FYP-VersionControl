import 'package:flutter/material.dart';
import '../slider/carousel_view.dart';
import '../progress/progress_details_view.dart';
import '../detection/detection_results_view.dart'; // Import DetectionResultView

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
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
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
                            const SizedBox(height: 5.0),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 20),

                                  // First Container
                                  Container(
                                    height: 350.0,
                                    width: MediaQuery.of(context).size.width * 0.95,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 310,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          clipBehavior: Clip.hardEdge,
                                          child: const PerformanceDetailsView(),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Second Container (Updated to call DetectionResultView)
                                  Container(
                                    height: 410.0,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(0),
                                    width: MediaQuery.of(context).size.width * 0.95,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: DetectionResultView(
                                        title: 'Detection Result',
                                      ),
                                    ),
                                  ),

                                  // Third Container
                                  Container(
                                    height: 190.0,
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(0),
                                    width: MediaQuery.of(context).size.width * 0.95,
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 180.0,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
