import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:banjir_beacon/config.dart';

class GeminiService {
  static const String _apiKey = AppConfig.geminiApiKey;

  static Future<Map<String, String>> analyzeFloodImage(dynamic imageFile) async {
    try {
      final model = GenerativeModel(
        model: "gemini-2.5-flash", // Use the standard flash model name
        apiKey: _apiKey,
      );

      final imageBytes = await imageFile.readAsBytes();
      
      final content = [
        Content.multi([
          TextPart("Analyze this flood image. Reply EXACTLY with this format:\nSeverity: [LOW, MODERATE, or SEVERE]\nDescription: [One short sentence explaining why]."),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? "";

      // ---------------------------------------------------------
      // DEBUG: Print exactly what Gemini said to your terminal!
      // ---------------------------------------------------------
      print("===== GEMINI RAW RESPONSE =====");
      print(text);
      print("===============================");

      // Bulletproof Parsing Logic (Ignores symbols, just looks for keywords)
      String upperText = text.toUpperCase();
      
      if (upperText.contains('SEVERITY:') && upperText.contains('DESCRIPTION:')) {
        
        // 1. Figure out the severity securely
        String severity = "LOW";
        if (upperText.contains('SEVERE')) {
          severity = "SEVERE";
        } else if (upperText.contains('MODERATE')) {
          severity = "MODERATE";
        }

        // 2. Extract the description (everything after the word "Description:")
        int descIndex = text.toLowerCase().indexOf('description:');
        String description = text.substring(descIndex + 12).trim();

        return {
          'severity': severity,
          'description': description,
        };
      }
      
      return {'severity': 'LOW', 'description': 'AI could not verify, please edit manually.'};

    } catch (e) {
      print("===== GEMINI ERROR =====");
      print(e);
      print("========================");
      return {'severity': 'LOW', 'description': 'AI connection error: $e'};
    }
  }
}
