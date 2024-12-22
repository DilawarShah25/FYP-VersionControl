import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DetectionResultView extends StatefulWidget {
  final String title;

  const DetectionResultView({
    super.key,
    required this.title,
  });

  @override
  _DetectionResultViewState createState() => _DetectionResultViewState();
}

class _DetectionResultViewState extends State<DetectionResultView> {
  File? _image;
  bool _isProcessing = false;
  bool _showResults = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isProcessing = false;
        _showResults = false;
      });
    }
  }

  void _showImageSourceActionSheet() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing with a delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isProcessing = false;
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.0,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Image, Processing Animation, or Results
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : _showResults
                  ? const Text(
                "Results: Detected Object Here!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              )
                  : _image != null
                  ? Image.file(
                _image!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
                  : const Text(
                "No Image Selected",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          // Show Results Button
          if (_image != null && !_showResults)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _processImage,
                child: const Text('Show Detected Results'),
              ),
            ),
          // Upload/Select Another Image Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showImageSourceActionSheet,
              child: Text(
                _image == null ? 'Upload Image' : 'Select Another Image',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
