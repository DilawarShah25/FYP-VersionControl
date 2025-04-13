import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../utils/circular_graph_painter.dart';
import '../app_theme.dart';

class DetectionResultView extends StatefulWidget {
  final String title;

  const DetectionResultView({
    super.key,
    required this.title,
  });

  @override
  State<DetectionResultView> createState() => _DetectionResultViewState();
}

class _DetectionResultViewState extends State<DetectionResultView> {
  File? _image;
  bool _isProcessing = false;
  String? _predictedLabel;
  double? _confidence;
  int totalUploads = 0;
  int withoutProblems = 0;
  int diagnosedProblems = 0;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = false;
        _predictedLabel = null;
        _confidence = null;
      });
    }
  }

  Future<void> _sendImageForPrediction() async {
    if (_image == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final url = Uri.parse('https://chigger-informed-mistakenly.ngrok-free.app/predict');
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        setState(() {
          _predictedLabel = responseData['predicted_label'];
          _confidence = responseData['confidence'];
          totalUploads++;
          if (_predictedLabel == 'normal') {
            withoutProblems++;
          } else {
            diagnosedProblems++;
          }
        });
      } else {
        _showError('Failed to get prediction');
      }
    } catch (e) {
      _showError('An error occurred');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: AppTheme.white)),
        backgroundColor: AppTheme.errorColor,
      ),
    );
    setState(() {
      _predictedLabel = 'Error';
      _confidence = 0.0;
    });
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Image Source', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppTheme.paddingSmall),
              ListTile(
                leading: const Icon(Icons.camera, color: AppTheme.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: AppTheme.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: AppTheme.errorColor),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.paddingMedium),
          Expanded(
            child: _buildContent(),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isProcessing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
        ),
      );
    }
    if (_predictedLabel != null && _confidence != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double size = min(constraints.maxWidth, constraints.maxHeight) * 0.7;
                return CustomPaint(
                  size: Size(size, size),
                  painter: CircularGraphPainter(confidence: _confidence!),
                  child: Center(
                    child: Text(
                      _predictedLabel!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(AppTheme.secondaryColor, 'Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%'),
              const SizedBox(width: AppTheme.paddingMedium),
              _buildLegendDot(AppTheme.errorColor, 'Remaining: ${(100 - _confidence! * 100).toStringAsFixed(2)}%'),
            ],
          ),
        ],
      );
    }
    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _image!,
          height: 200,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Text('Error loading image'),
        ),
      );
    }
    return Center(
      child: Text(
        'No Image Selected',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        if (_image != null && _predictedLabel == null)
          ElevatedButton(
            onPressed: _sendImageForPrediction,
            child: const Text('Show Results'),
          ),
        const SizedBox(height: AppTheme.paddingSmall),
        OutlinedButton(
          onPressed: _showImageSourceActionSheet,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _image == null ? 'Upload Image' : 'Select Another Image',
            style: const TextStyle(color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.paddingSmall),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }
}