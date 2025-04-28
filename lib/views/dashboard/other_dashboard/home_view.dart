import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../DetectionAndPrevention/view/camera_screen_view.dart';
import '../../../DetectionAndPrevention/view/upload_history.dart';
import '../../../tflite_model.dart';
import '../../../utils/app_theme.dart';
import '../../progress/progress_history_view.dart';
import '../../slider/carousel_view.dart';
import '../../../DetectionAndPrevention/controller/detection_result_controller.dart';
import '../../../DetectionAndPrevention/model/detection_result_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<CameraDescription>? cameras;
  late DetectionResultController detectionController;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    detectionController = DetectionResultController(
      model: DetectionResultModel(),
      onError: (errorMessage) {
        debugPrint('Detection error: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $errorMessage')),
        );
      },
    );
    debugPrint('DetectionResultController initialized');
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
      debugPrint('Cameras initialized: ${cameras?.length}');
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCarouselSection(size),
              _buildBodyContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSection(Size size) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      child: const Carousel(
        images: [
          'lib/assets/images/carousel_item1.png',
          'lib/assets/images/carousel_item2.png',
          'lib/assets/images/carousel_item3.png',
          'lib/assets/images/carousel_item4.png',
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Early Detection\nMakes a Difference',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          _buildCard(
            height: 330,
            child: const ProgressHistoryView(),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          _buildActionButtonsContainer(),
          const SizedBox(height: AppTheme.paddingMedium),
          _buildCard(
            height: 200,
            child: const UploadHistory(
              totalUploads: 10,
              withoutProblems: 7,
              diagnosedProblems: 3,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildActionButtonsContainer() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildActionButtonsGrid(),
    );
  }

  Widget _buildActionButtonsGrid() {
    final buttonData = [
      {'icon': Icons.search, 'label': 'Detect Now'},
      {'icon': Icons.history, 'label': 'View History'},
      {'icon': Icons.recommend, 'label': 'Last Recommendations'},
      {'icon': Icons.trending_up, 'label': 'Progress Tracker'},
    ];

    return Column(
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.paddingSmall,
            crossAxisSpacing: AppTheme.paddingSmall,
            childAspectRatio: 2.8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: buttonData.length,
          itemBuilder: (context, index) {
            return _buildActionButton(
              icon: buttonData[index]['icon'] as IconData,
              label: buttonData[index]['label'] as String,
              onPressed: () async {
                if (index == 0) {
                  if (cameras != null && cameras!.isNotEmpty) {
                    debugPrint('Navigating to CameraScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraScreen(
                          cameras: cameras!,
                          controller: detectionController,
                        ),
                      ),
                    );
                  } else {
                    debugPrint('No cameras available');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No camera available')),
                    );
                  }
                }
              },
            );
          },
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width / 2 - AppTheme.paddingMedium * 2 - 20,
              child: _buildActionButton(
                icon: Icons.upload,
                label: 'Test TFLITE',
                onPressed: () {
                  debugPrint('Test TFLITE button pressed');
                  // if (cameras != null && cameras!.isNotEmpty) {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => //TFLitePredictionScreen(cameras: cameras!),
                  //     ),
                  //   );
                  // } else {
                  //   debugPrint('No cameras available');
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('No cameras available')),
                  //   );
                  // }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }




  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 16,
        color: AppTheme.primaryColor,
      ),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.backgroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.paddingSmall / 2,
          vertical: AppTheme.paddingSmall / 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppTheme.primaryColor, width: 1),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildCard({required double height, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: AppTheme.cardDecoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}