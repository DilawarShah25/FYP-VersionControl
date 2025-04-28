// import 'dart:io';
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import '../../../utils/app_theme.dart';
//
// class TFLitePredictionScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//
//   const TFLitePredictionScreen({super.key, required this.cameras});
//
//   @override
//   State<TFLitePredictionScreen> createState() => _TFLitePredictionScreenState();
// }
//
// class _TFLitePredictionScreenState extends State<TFLitePredictionScreen> {
//   CameraController? _cameraController;
//   XFile? _capturedImage;
//   bool _isLoading = false;
//   bool _isModelLoaded = false;
//   String? _prediction;
//   double? _confidence;
//   String? _errorMessage;
//   Interpreter? _interpreter;
//   final List<String> _labels = ['Invalid', 'Normal', 'Stage 1', 'Stage 2', 'Stage 3'];
//
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _loadTFLiteModel();
//   }
//
//   Future<void> _initializeCamera() async {
//     if (widget.cameras.isEmpty) {
//       setState(() => _errorMessage = 'No cameras available');
//       return;
//     }
//     _cameraController = CameraController(
//       widget.cameras[0], // Use the first available camera
//       ResolutionPreset.high,
//     );
//     try {
//       await _cameraController!.initialize();
//       if (mounted) setState(() {});
//     } catch (e) {
//       debugPrint('Error initializing camera: $e');
//       setState(() => _errorMessage = 'Error initializing camera: $e');
//     }
//   }
//
//   Future<void> _loadTFLiteModel() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//     try {
//       final conditions = FirebaseModelDownloadConditions(
//         iosAllowsCellularAccess: false,
//         iosAllowsBackgroundDownloading: false,
//         androidWifiRequired: false,
//         androidChargingRequired: false,
//         androidDeviceIdleRequired: false,
//       );
//       final customModel = await FirebaseModelDownloader.instance.getModel(
//         'Hair_Loss_Detector',
//         FirebaseModelDownloadType.localModelUpdateInBackground,
//         conditions,
//       );
//
//       final modelPath = customModel.file.path;
//       debugPrint('File size: ${File(modelPath).lengthSync()} bytes');
//       debugPrint('Model file path: $modelPath');
//       debugPrint('File exists: ${File(modelPath).existsSync()}');
//       _interpreter = await Interpreter.fromFile(File(modelPath));
//       setState(() {
//         _isModelLoaded = true;
//         debugPrint('Model loaded successfully from $modelPath');
//       });
//     } catch (e) {
//       debugPrint('Error loading model from Firebase: $e');
//       setState(() {
//         _errorMessage = 'Failed to load model: $e';
//       });
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _captureImage() async {
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized ||
//         !_isModelLoaded ||
//         _interpreter == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(_isModelLoaded
//               ? 'Camera not ready'
//               : 'Model not loaded. Please try again.'),
//         ),
//       );
//       return;
//     }
//     setState(() => _isLoading = true);
//     try {
//       final image = await _cameraController!.takePicture();
//       setState(() {
//         _capturedImage = image;
//         _prediction = null;
//         _confidence = null;
//       });
//       await _runInference(image.path);
//     } catch (e) {
//       debugPrint('Error capturing image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error capturing image: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _runInference(String imagePath) async {
//     // Preprocess the image (resize to 224x224)
//     final image = img.decodeImage(File(imagePath).readAsBytesSync())!;
//     final resizedImage = img.copyResize(image, width: 224, height: 224);
//
//     // Prepare input buffer (1x224x224x3, float32)
//     final input = Float32List(1 * 224 * 224 * 3);
//     int index = 0;
//     for (var y = 0; y < 224; y++) {
//       for (var x = 0; x < 224; x++) {
//         final pixel = resizedImage.getPixel(x, y);
//         input[index++] = (pixel.r / 255.0 - 0.5) / 0.5; // Red, normalize to [-1, 1]
//         input[index++] = (pixel.g / 255.0 - 0.5) / 0.5; // Green
//         input[index++] = (pixel.b / 255.0 - 0.5) / 0.5; // Blue
//       }
//     }
//
//     // Prepare output buffer (1x5 for 5 classes)
//     final output = Float32List(1 * 5).reshape([1, 5]);
//
//     // Run inference
//     _interpreter!.run(input.reshape([1, 224, 224, 3]), output);
//
//     // Process output
//     final probabilities = output[0];
//     final maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
//     final confidence = probabilities[maxIndex];
//
//     setState(() {
//       _prediction = _labels[maxIndex];
//       _confidence = confidence * 100;
//     });
//   }
//
//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     _interpreter?.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: AppTheme.backgroundColor,
//       appBar: AppBar(
//         title: const Text('Hair Loss Detection'),
//         backgroundColor: AppTheme.primaryColor,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(AppTheme.paddingMedium),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               // Error Message or Retry Button
//               if (_errorMessage != null)
//                 Container(
//                   padding: const EdgeInsets.all(AppTheme.paddingMedium),
//                   decoration: BoxDecoration(
//                     color: Colors.red[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         _errorMessage!,
//                         style: const TextStyle(color: Colors.red),
//                         textAlign: TextAlign.center,
//                       ),
//                       const SizedBox(height: AppTheme.paddingSmall),
//                       ElevatedButton(
//                         onPressed: _loadTFLiteModel,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppTheme.primaryColor,
//                         ),
//                         child: const Text(
//                           'Retry',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               if (_errorMessage != null)
//                 const SizedBox(height: AppTheme.paddingLarge),
//               // Camera Preview or Captured Image
//               Container(
//                 width: size.width * 0.9,
//                 height: size.width * 0.9,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: _capturedImage == null
//                       ? (_cameraController != null &&
//                       _cameraController!.value.isInitialized
//                       ? CameraPreview(_cameraController!)
//                       : const Center(child: Text('Camera not available')))
//                       : Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
//                 ),
//               ),
//               const SizedBox(height: AppTheme.paddingLarge),
//               // Capture Button
//               ElevatedButton.icon(
//                 onPressed: _isModelLoaded ? _captureImage : null,
//                 icon: const Icon(Icons.camera_alt, color: Colors.white),
//                 label: const Text(
//                   'Capture Image',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isModelLoaded
//                       ? AppTheme.primaryColor
//                       : Colors.grey,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppTheme.paddingLarge,
//                     vertical: AppTheme.paddingMedium,
//                   ),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: AppTheme.paddingLarge),
//               // Prediction Result
//               if (_prediction != null)
//                 Container(
//                   width: size.width * 0.9,
//                   padding: const EdgeInsets.all(AppTheme.paddingMedium),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Prediction Result',
//                         style: Theme.of(context).textTheme.headlineSmall,
//                       ),
//                       const SizedBox(height: AppTheme.paddingSmall),
//                       Text(
//                         _prediction!,
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: _prediction == 'Normal'
//                               ? Colors.green
//                               : _prediction == 'Invalid'
//                               ? Colors.red
//                               : Colors.orange,
//                         ),
//                       ),
//                       const SizedBox(height: AppTheme.paddingSmall),
//                       Text(
//                         'Confidence: ${_confidence!.toStringAsFixed(2)}%',
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       const SizedBox(height: AppTheme.paddingSmall),
//                       // Visual Confidence Bar
//                       LinearProgressIndicator(
//                         value: _confidence! / 100,
//                         backgroundColor: Colors.grey[300],
//                         color: AppTheme.primaryColor,
//                         minHeight: 8,
//                       ),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }