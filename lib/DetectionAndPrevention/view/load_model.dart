import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HairLossDetector extends StatefulWidget {
  const HairLossDetector({Key? key}) : super(key: key);

  @override
  _HairLossDetectorState createState() => _HairLossDetectorState();
}

class _HairLossDetectorState extends State<HairLossDetector> {
  Interpreter? _interpreter; // Made nullable to handle failure cases
  List<String> _labels = [];
  String result = '';
  String imagePath = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadLabels();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model1.tflite'); // Ensure correct path
      debugPrint("✅ TFLite model loaded successfully.");
    } catch (e) {
      debugPrint("❌ Error loading TFLite model: $e");
      setState(() {
        result = "❌ Failed to load model. Please check the app setup.";
      });
    }
  }

  Future<void> _loadLabels() async {
    try {
      final String labelsData = await DefaultAssetBundle.of(context)
          .loadString('assets/labels1.txt'); // Ensure correct path
      setState(() {
        _labels = labelsData.split('\n').map((e) => e.trim()).toList();
      });
      debugPrint("✅ Labels loaded successfully: ${_labels.length} labels.");
    } catch (e) {
      debugPrint("❌ Error loading labels: $e");
      setState(() {
        result = "❌ Failed to load labels. Please check the app setup.";
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final XFile? pickedImage =
    await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        imagePath = pickedImage.path;
      });
      await _detectDisease();
    } else {
      setState(() {
        result = "⚠ No image selected.";
      });
    }
  }

  Future<void> _detectDisease() async {
    // Check if the image file exists
    if (!File(imagePath).existsSync()) {
      setState(() {
        result = "⚠ Image file not found!";
      });
      return;
    }

    // Check if the interpreter is loaded
    if (_interpreter == null) {
      setState(() {
        result = "❌ Model not loaded. Please restart the app.";
      });
      return;
    }

    try {
      File imageFile = File(imagePath);
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) {
        setState(() {
          result = "⚠ Failed to decode image!";
        });
        return;
      }
      image = img.copyResize(image, width: 224, height: 224);

      var input = List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = image!.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      );

      var inputBuffer = [input];

      var output =
      List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      _interpreter!.run(inputBuffer, output);

      int predictedIndex = output[0].indexOf(
          output[0].reduce((a, b) => a > b ? a : b));

      String disease = _getDiseaseLabel(predictedIndex);

      setState(() {
        result = "Prediction: $disease";
      });

      await _storeDetectionResult(disease);
      await showTreatmentDialog(context, disease.replaceAll(' ', ''));
    } catch (e) {
      debugPrint("❌ Error during detection: $e");
      setState(() {
        result = "❌ Detection failed: $e";
      });
    }
  }

  String _getDiseaseLabel(int index) {
    if (_labels.isEmpty) {
      return "Labels not loaded";
    }
    if (index < _labels.length) {
      return _labels[index];
    }
    return "Unknown";
  }

  Future<void> _storeDetectionResult(String disease) async {
    debugPrint("📦 Stored result: $disease");
  }

  Future<void> showTreatmentDialog(BuildContext context, String disease) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Treatment Info"),
        content: Text("Treatment details for $disease (sample text)."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hair Loss Detector"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath.isNotEmpty)
              Image.file(File(imagePath), height: 200),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImageFromCamera,
              child: const Text("Capture Image"),
            ),
          ],
        ),
      ),
    );
  }
}