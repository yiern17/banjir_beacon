import 'dart:io';
import 'package:flutter/foundation.dart'; // 1. Add this for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banjir_beacon/services/gemini_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  XFile? _imageFile; // 2. Use XFile instead of File for cross-platform support
  bool _isAnalyzing = false;
  bool _manualMode = false;
  String _severity = "LOW";
  final TextEditingController _descController = TextEditingController();

  Future<void> _snapAndAnalyze() async {
    final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _imageFile = photo; // 3. Store the XFile directly
      _isAnalyzing = true;
      _manualMode = false;
    });

    // 4. Update your GeminiService to accept XFile or use photo.path
    // This part depends on your teammate's service implementation
    final result = await GeminiService.analyzeFloodImage(_imageFile!);

    setState(() {
      _isAnalyzing = false;
      

    // If AI fails (which it is currently doing), we MUST stay in a valid state
  if (result['severity'] == "INVALID" || result['severity'] == "UNKNOWN") {
    _manualMode = false; 
    _severity = "LOW"; // CRITICAL: This prevents the black screen crash
    _descController.text = result['description'] ?? "Error"; 
  } else {
    // Only set the AI result if it matches your dropdown exactly
    _severity = result['severity']!;
    _descController.text = result['description']!;
    _manualMode = true; 
  };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Report"), leading: const CloseButton()),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isAnalyzing 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text("AI Verifying Hazard...")],
            ))
          : SingleChildScrollView(child: _buildUI()),
      ),
    );
  }

  // 5. Helper widget to display image correctly on Web vs Mobile
  Widget _displayImage(double height) {
    if (kIsWeb) {
      return Image.network(_imageFile!.path, height: height, width: double.infinity, fit: BoxFit.cover);
    } else {
      return Image.file(File(_imageFile!.path), height: height, width: double.infinity, fit: BoxFit.cover, cacheHeight: 400);
    }
  }

  Widget _buildUI() {
    if (_imageFile == null) {
      return Column(
        children: [
          const Icon(Icons.camera_enhance_outlined, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text("Take a photo to report the hazard.", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _snapAndAnalyze,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.redAccent),
            child: const Text("OPEN CAMERA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (!_manualMode && !_isAnalyzing) {
      return Column(
        children: [
          _displayImage(200), // Use helper
          const SizedBox(height: 20),
          const Text("AI could not verify this as a flood.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _snapAndAnalyze, child: const Text("RETAKE PHOTO")),
          TextButton(
            onPressed: () => setState(() => _manualMode = true), 
            child: const Text("I'M SURE IT'S A FLOOD (REPORT MANUALLY)")
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: _displayImage(180)), // Use helper
        const SizedBox(height: 20),
        const Text("Severity Level", style: TextStyle(fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          value: _severity,
          items: ["LOW", "MODERATE", "SEVERE"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _severity = v!),
        ),
        const SizedBox(height: 20),
        const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(hintText: "Enter details manually...")),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report Sent!"), backgroundColor: Colors.green));
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.blue[900]),
          child: const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}