import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

import '../../utils/circular_graph_painter.dart';
// import 'upload_history.dart'; // Import the second file

class DetectionResultView extends StatefulWidget {
  final String title;

  const DetectionResultView({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _DetectionResultViewState createState() => _DetectionResultViewState();
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
      final url = Uri.parse(
          'https://chigger-informed-mistakenly.ngrok-free.app/predict');
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        setState(() {
          _predictedLabel = responseData['predicted_label'];
          _confidence = responseData['confidence'];

          // Update totals based on predicted label
          totalUploads++;
          if (_predictedLabel == 'normal') {
            withoutProblems++;
          } else {
            diagnosedProblems++;
          }
        });
      } else {
        setState(() {
          _predictedLabel = 'Error';
          _confidence = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _predictedLabel = 'Error';
        _confidence = 0.0;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.blue),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.blue),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: 400.0,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6FB1FC),
              Color(0xFF4364F7),
              Color(0xFF0052D4),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
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
        ),
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Image, Processing Animation, or Results
            Expanded(
              child: _isProcessing
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellowAccent),
                  strokeWidth: 5,
                ),
              )
                  : (_predictedLabel != null && _confidence != null)
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double size = min(constraints.maxWidth,
                            constraints.maxHeight) *
                            0.7;
                        return CustomPaint(
                          size: Size(size, size),
                          painter: CircularGraphPainter(
                              confidence: _confidence!),
                          child: Center(
                            child: Text(
                              _predictedLabel!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendDot(Colors.greenAccent,
                          'Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%'),
                      const SizedBox(width: 20),
                      _buildLegendDot(Colors.red,
                          'Remaining: ${(100 - _confidence! * 100).toStringAsFixed(2)}%'),
                    ],
                  ),
                ],
              )
                  : _image != null
                  ? Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text("Error loading image");
                },
              )
                  : const Align(
                alignment: Alignment.center,
                child: Text(
                  "No Image Selected",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Buttons with gradient style
            if (_image != null && _predictedLabel == null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 95.0),
                    backgroundColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _sendImageForPrediction,
                  child: const Text(
                    'Show Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 70.0),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _showImageSourceActionSheet,
                child: Text(
                  _image == null ? 'Upload Image' : 'Select Another Image',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
