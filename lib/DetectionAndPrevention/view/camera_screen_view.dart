import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_theme.dart';
import '../controller/detection_result_controller.dart';
import 'detection_results_view.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final DetectionResultController controller;

  const CameraScreen({
    Key? key,
    required this.cameras,
    required this.controller,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  int _selectedCameraIndex = 0;
  bool _isScanning = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera(widget.cameras[_selectedCameraIndex]);

    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_scanAnimationController)
      ..addListener(() {
        setState(() {});
      });
  }

  void _initializeCamera(CameraDescription camera) {
    _cameraController = CameraController(camera, ResolutionPreset.high);
    _initializeControllerFuture = _cameraController.initialize().catchError((e) {
      debugPrint('Camera init error: $e');
    });
  }

  void _switchCamera() async {
    if (_isScanning) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    });

    await _cameraController.dispose();
    _initializeCamera(widget.cameras[_selectedCameraIndex]);
    setState(() {});
  }

  void _pickImageFromGallery() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _isScanning = false);
        return;
      }

      _scanAnimationController.forward(from: 0).whenComplete(() {
        final imageFileObj = File(image.path);
        widget.controller.model.setImage(imageFileObj);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionResultView(
              title: 'Detection Results',
              controller: widget.controller,
            ),
          ),
        );

        setState(() => _isScanning = false);
        _scanAnimationController.reset();
      });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking image: $e',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  ignoring: _isScanning,
                  child: CameraPreview(_cameraController),
                ),
                HeadPositionOverlay(
                  isScanning: _isScanning,
                  scanProgress: _scanAnimation.value,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: AppTheme.paddingSmall,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.paddingLarge),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FloatingActionButton(
                          onPressed: () async {
                            if (_isScanning) return;

                            setState(() => _isScanning = true);
                            XFile? imageFile;

                            try {
                              imageFile = await _cameraController.takePicture();
                            } catch (e) {
                              setState(() => _isScanning = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error capturing image: $e',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                              return;
                            }

                            _scanAnimationController.forward(from: 0).whenComplete(() {
                              final imageFileObj = File(imageFile!.path);
                              widget.controller.model.setImage(imageFileObj);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetectionResultView(
                                    title: 'Detection Results',
                                    controller: widget.controller,
                                  ),
                                ),
                              );

                              setState(() => _isScanning = false);
                              _scanAnimationController.reset();
                            });
                          },
                          backgroundColor: AppTheme.white,
                          foregroundColor: AppTheme.primaryColor,
                          child: const Icon(Icons.camera),
                        ),
                        const SizedBox(width: AppTheme.paddingMedium),
                        FloatingActionButton(
                          onPressed: _pickImageFromGallery,
                          backgroundColor: AppTheme.white,
                          foregroundColor: AppTheme.primaryColor,
                          child: const Icon(Icons.photo_library),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: AppTheme.paddingLarge,
                  right: AppTheme.paddingSmall + 30,
                  child: IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: AppTheme.white),
                    onPressed: _switchCamera,
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
              ),
            );
          }
        },
      ),
    );
  }
}

class HeadPositionOverlay extends StatelessWidget {
  final bool isScanning;
  final double scanProgress;

  const HeadPositionOverlay({
    Key? key,
    required this.isScanning,
    required this.scanProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          painter: HeadFramePainter(
            isScanning: isScanning,
            scanProgress: scanProgress,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15 - 30,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Scan your scalp',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HeadFramePainter extends CustomPainter {
  final bool isScanning;
  final double scanProgress;

  HeadFramePainter({required this.isScanning, required this.scanProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.75,
      height: size.height * 0.45,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(ovalRect);
    final combinedPath = Path.combine(PathOperation.difference, backgroundPath, ovalPath);

    canvas.drawPath(combinedPath, backgroundPaint);

    final borderPaint = Paint()
      ..color = AppTheme.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dashPath = Path();
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double distance = 0.0;
    final pathMetric = ovalPath.computeMetrics().first;

    while (distance < pathMetric.length) {
      dashPath.addPath(
        pathMetric.extractPath(distance, distance + dashWidth),
        Offset.zero,
      );
      distance += dashWidth + dashSpace;
    }
    canvas.drawPath(dashPath, borderPaint);

    if (isScanning) {
      final scanPaint = Paint()
        ..color = AppTheme.secondaryColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      final startAngle = 2 * math.pi * scanProgress;
      const sweepAngle = math.pi / 4;
      canvas.drawArc(ovalRect, startAngle, sweepAngle, false, scanPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}