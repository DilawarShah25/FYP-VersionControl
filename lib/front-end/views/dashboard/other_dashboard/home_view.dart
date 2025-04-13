import 'package:flutter/material.dart';
import '../../app_theme.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carousel Section
              _buildCarouselSection(size),
              // Body Content
              _buildBodyContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselSection(Size size) {
    return Container(
      // height: size.height * 0.4,
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      child: const Carousel(
        images: [
          'lib/front-end/assets/images/carousel_item1.png',
          'lib/front-end/assets/images/carousel_item2.png',
          'lib/front-end/assets/images/carousel_item3.png',
          'lib/front-end/assets/images/carousel_item4.png',
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
          // Performance Details
          _buildCard(
            height: 330,
            child: const PerformanceDetailsView(),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          // Upload History
          _buildCard(
            height: 200,
            child: const UploadHistory(
              totalUploads: 10,
              withoutProblems: 7,
              diagnosedProblems: 3,
            ),
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          // Detection Results
          _buildCard(
            height: 400,
            child: const DetectionResultView(title: 'Detection Result'),
          ),
        ],
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