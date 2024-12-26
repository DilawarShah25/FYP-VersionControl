import 'package:flutter/material.dart';
import '../../detection/detection_results_view.dart';
import '../../detection/upload_history.dart';
import '../../progress/progress_details_view.dart';
import '../../slider/carousel_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.yellow,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom AppBar with Carousel
              Container(
                height: 550, // Height for the carousel
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Carousel(
                  images: [
                    'lib/front-end/assets/images/carousel_item1.png',
                    'lib/front-end/assets/images/carousel_item2.png',
                    'lib/front-end/assets/images/carousel_item3.png',
                    'lib/front-end/assets/images/carousel_item4.png',
                  ],
                ),
              ),

              // Body Content
              Container(
                color: Colors.blue[50],
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFA5FECB),
                            Color(0xFF20BDFF),
                            Color(0xFF5433FF)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
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

                            // First Container
                            Container(
                              height: 280.0,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue[200]!,
                                    Colors.lightBlue[50]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue[100]!, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: const PerformanceDetailsView(),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Container(
                              height: 190.0,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange[200]!,
                                    Colors.orange[100]!,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.deepOrangeAccent,
                                  width: 1.5,
                                ),
                              ),
                              child: const UploadHistory(
                                totalUploads: 10, // Replace with your dynamic value
                                withoutProblems: 7, // Replace with your dynamic value
                                diagnosedProblems: 3, // Replace with your dynamic value
                              ),
                            ),

                            const SizedBox(height: 20),
                            // Second Container
                            Container(
                              height: 390.0,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.lightGreen[100]!,
                                    Colors.lightGreen[50]!
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.greenAccent, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: const DetectionResultView(
                                  title: 'Detection Result',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Third Container
                            Container(
                              height: 190.0,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange[200]!,
                                    Colors.orange[100]!
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.deepOrangeAccent, width: 1.5),
                              ),
                              child: Center(
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
                    )
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
