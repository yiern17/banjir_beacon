import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:banjir_beacon/config.dart';

class GeminiService {
  static const String _apiKey = AppConfig.geminiApiKey;

  static Future<Map<String, String>> analyzeFloodImage(File imageFile) async {
    try {
      // FIX: Use 'gemini-1.5-flash' which is the stable model name
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: _apiKey,
      );
      
      final prompt = TextPart(
        "Is there a flood or water hazard in this image? "
        "Return ONLY this format: Severity: [LOW/MODERATE/SEVERE] | Description: [1 sentence]."
      );

      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          prompt, 
          DataPart('image/jpeg', imageBytes)
        ])
      ];

      // Note: If you still get a 404, your API key might not be 
      // enabled for the 'Generative Language API' in Google Cloud.
      final response = await model.generateContent(content);
      final text = response.text ?? "";
      
      if (text.contains('|')) {
        final parts = text.split('|');
        return {
          'severity': parts[0].replaceAll('Severity:', '').trim(),
          'description': parts[1].replaceAll('Description:', '').trim(),
        };
      }
      return {'severity': 'INVALID', 'description': 'AI could not verify hazard.'};
    } catch (e) {
      print("CRITICAL ERROR: $e");
      // Return UNKNOWN so our Manual Report screen triggers
      return {'severity': 'UNKNOWN', 'description': 'AI connection error.'};
    }
  }
}