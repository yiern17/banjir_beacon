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

// import 'dart:io';
// import 'package:flutter/foundation.dart'; // Required for kIsWeb
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:banjir_beacon/config.dart';

// class GeminiService {
//   static const String _apiKey = AppConfig.geminiApiKey;

//   // Changed input type to 'dynamic' to handle both File (Mobile) and XFile (Web)
//   static Future<Map<String, String>> analyzeFloodImage(dynamic imageFile) async {
//     try {
//       print("DEBUG: 1. Start Gemini Service");
//       final model = GenerativeModel(model: 'models/gemini-1.5-flash', apiKey: _apiKey);
      
//       print("DEBUG: 2. Reading bytes from image");
//       final imageBytes = await imageFile.readAsBytes();
      
//       print("DEBUG: 3. Sending request to Google AI...");
//       final response = await model.generateContent([
//         Content.multi([
//           TextPart("Analyze this flood image. Return format: Severity: [LOW/MODERATE/SEVERE] | Description: [1 sentence]."), 
//           DataPart('image/jpeg', imageBytes)
//         ])
//       ]);

//       final text = response.text ?? "";
//       print("DEBUG: 4. AI Response received: $text");

//       // PARSING LOGIC: This must be present to return a value
//       if (text.contains('|')) {
//         final parts = text.split('|');
//         String severity = parts[0].toUpperCase().replaceAll('SEVERITY:', '').trim();
        
//         // Ensure the value matches your Dropdown exactly to prevent the black screen crash
//         if (!["LOW", "MODERATE", "SEVERE"].contains(severity)) {
//            severity = "LOW"; 
//         }

//         return {
//           'severity': severity,
//           'description': parts[1].replaceAll('Description:', '').trim(),
//         };
//       }
      
//       print("DEBUG: 5. Response didn't contain '|', returning INVALID");
//       return {'severity': 'INVALID', 'description': 'AI could not verify hazard.'};

//     } catch (e) {
//       print("DEBUG: CRITICAL ERROR FOUND: $e");
//       return {'severity': 'UNKNOWN', 'description': 'AI connection error: $e'};
//     }
//   }
  // static Future<Map<String, String>> analyzeFloodImage(dynamic imageFile) async {
  //   try {
  //     print("Attempting to connect to Gemini..."); // Debugging line
  //     final model = GenerativeModel(
  //       model: 'gemini-1.5-flash',
  //       apiKey: _apiKey,
  //     );

  //     // Improve the prompt to be more specific and "AI-proof"
  //     final prompt = TextPart(
  //       "Analyze this image for flood hazards. Respond EXACTLY in this format: "
  //       "Severity: [LOW, MODERATE, or SEVERE] | Description: [One sentence about the water level]."
  //     );

  //     // Use readAsBytes() which is available on both File and XFile
  //     final imageBytes = await imageFile.readAsBytes();
  //     print("Bytes loaded successfully: ${imageBytes.length}"); // Debugging line
      
  //     final content = [
  //       Content.multi([
  //       TextPart("Analyze this flood image. Return format: Severity: [LOW/MODERATE/SEVERE] | Description: [1 sentence]."),
  //       DataPart('image/jpeg', imageBytes),
  //     ])
  //     ];

  //     final response = await model.generateContent(content);
  //     final text = response.text ?? "";
      
  //     // Better parsing: Handle case sensitivity and missing pipes
  //     if (text.contains('|')) {
  //       final parts = text.split('|');
  //       // Convert to Uppercase to match your Dropdown items exactly
  //       String severity = parts[0].toUpperCase().replaceAll('SEVERITY:', '').trim();
        
  //       // Ensure it's a valid choice for your dropdown
  //       if (!["LOW", "MODERATE", "SEVERE"].contains(severity)) {
  //          severity = "LOW"; 
  //       }

  //       return {
  //         'severity': severity,
  //         'description': parts[1].replaceAll('Description:', '').trim(),
  //       };
  //     }
      
  //     return {'severity': 'INVALID', 'description': 'AI could not verify hazard.'};
  //   } catch (e) {
  //     print("CRITICAL ERROR: $e");
  //     return {'severity': 'UNKNOWN', 'description': 'AI connection error: $e'};
  //   }
  // }
