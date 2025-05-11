import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectionResultModel {
  File? image;
  bool isProcessing = false;

  String? validity;
  String? prediction;
  Map<String, double>? probabilities; // Store probabilities as a map

  int totalUploads = 0;
  int withoutProblems = 0;
  int diagnosedProblems = 0;

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

        validity = responseData['validity'];

        if (validity == 'Valid Image') {
          prediction = responseData['prediction'];
          // Parse probabilities
          probabilities = Map<String, double>.from(responseData['probabilities']);
          totalUploads++;
          if (prediction == 'Normal') {
            withoutProblems++;
          } else {
            diagnosedProblems++;
          }
        } else {
          prediction = null;
          probabilities = null;
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
    validity = null;
    prediction = null;
    probabilities = null;
    isProcessing = false;
  }

  void reset() {
    image = null;
    validity = null;
    prediction = null;
    probabilities = null;
    isProcessing = false;
    totalUploads = 0;
    withoutProblems = 0;
    diagnosedProblems = 0;
  }
}