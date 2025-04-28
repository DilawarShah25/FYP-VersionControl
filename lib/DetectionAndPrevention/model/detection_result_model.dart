import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectionResultModel {
  File? image;
  bool isProcessing = false;
  String? predictedLabel;
  double? confidence;
  int totalUploads = 0;
  int withoutProblems = 0;
  int diagnosedProblems = 0;

  set result(String result) {}

  Future<void> sendImageForPrediction() async {
    if (image == null) return;

    isProcessing = true;

    try {
      final url = Uri.parse('https://chigger-informed-mistakenly.ngrok-free.app/predict');
      final request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('image', image!.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        predictedLabel = responseData['predicted_label'];
        confidence = (responseData['confidence'] as num).toDouble(); // Ensure double
        totalUploads++;
        if (predictedLabel == 'normal') {
          withoutProblems++;
        } else {
          diagnosedProblems++;
        }
      } else {
        throw Exception('Failed to get prediction');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    } finally {
      isProcessing = false;
    }
  }

  void setImage(File? newImage) {
    image = newImage;
    predictedLabel = null;
    confidence = null;
    isProcessing = false;
  }

  void reset() {
    image = null;
    predictedLabel = null;
    confidence = null;
    isProcessing = false;
    totalUploads = 0;
    withoutProblems = 0;
    diagnosedProblems = 0;
  }
}