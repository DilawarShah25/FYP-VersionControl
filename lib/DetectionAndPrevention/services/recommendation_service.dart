import 'package:flutter_gemini/flutter_gemini.dart';

class RecommendationService {
  static const String _apiKey = 'AIzaSyBg9SpnYVHFqEfLwGgFL9mgKQsvgytVpwc';

  RecommendationService() {
    _initializeGemini();
  }

  void _initializeGemini() {
    try {
      Gemini.init(apiKey: _apiKey);
    } catch (e) {
      throw Exception('Failed to initialize Gemini API: $e');
    }
  }

  Future<String> getRecommendation(String prediction) async {
    try {
      final gemini = Gemini.instance;
      final prompt = _getRecommendationPrompt(prediction);
      final response = await gemini.prompt(parts: [
        Part.text(prompt),
      ]);

      if (response == null || response.output == null) {
        return 'Unable to generate recommendation at this time.';
      }

      return response.output!.trim();
    } catch (e) {
      throw Exception('Error fetching recommendation: $e');
    }
  }

  Future<String> chatWithGemini(String prediction, String userMessage) async {
    try {
      final gemini = Gemini.instance;
      final prompt = '''
        You are a scalp care expert. The user has been diagnosed with $prediction on their scalp. 
        They have asked: "$userMessage"
        Provide a concise, professional response (1-2 sentences) related to scalp care or the diagnosed condition.
      ''';
      final response = await gemini.prompt(parts: [
        Part.text(prompt),
      ]);

      if (response == null || response.output == null) {
        return 'Unable to respond at this time.';
      }

      return response.output!.trim();
    } catch (e) {
      throw Exception('Error during chat: $e');
    }
  }

  String _getRecommendationPrompt(String prediction) {
    return '''
      You are a scalp care expert. Provide a simple, short, and precise recommendation (1-2 sentences) based on the following diagnosis: $prediction. Use the guidelines below:
      - For Stage 1: Suggest using Topical Minoxidil (5%) twice daily on the affected area for 3-6 months, and consider Oral Finasteride (1 mg daily) with a dermatologist's advice to slow progression.
      - For Stage 2: Recommend consulting a dermatologist for a tailored treatment plan, and suggest gentle scalp care with a mild shampoo.
      - For Normal: Confirm the hair is healthy and suggest maintaining it with regular cleansing and hydration.
      - For Invalid: Ask the user to upload or capture a valid image.
      - For Stage 3: Urgently recommend consulting a dermatologist.
      - For diseases (e.g., AlopeciaAreata, AndrogeneticAlopecia): State the diagnosis and strongly suggest consulting a dermatologist.
      Keep the response concise and professional.
    ''';
  }
}