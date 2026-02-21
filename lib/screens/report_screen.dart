import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:banjir_beacon/services/gemini_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _image;
  bool _isAnalyzing = false;
  bool _manualMode = false;
  String _severity = "LOW";
  final TextEditingController _descController = TextEditingController();

  Future<void> _snapAndAnalyze() async {
    final XFile? photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() {
      _image = File(photo.path);
      _isAnalyzing = true;
      _manualMode = false;
    });

    final result = await GeminiService.analyzeFloodImage(_image!);

    setState(() {
      _isAnalyzing = false;
      // If AI fails, we don't show the form yet, we show the "Failure" UI
      if (result['severity'] == "INVALID" || result['severity'] == "UNKNOWN") {
        _manualMode = false; // Stay in 'failed' view
      } else {
        _severity = result['severity']!;
        _descController.text = result['description']!;
        _manualMode = true; // AI worked, show the form
      }
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

  Widget _buildUI() {
    // 1. Initial State: No photo yet
    if (_image == null) {
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

    // 2. Failed State: AI didn't recognize it
    if (!_manualMode && !_isAnalyzing) {
      return Column(
        children: [
          Image.file(_image!, height: 200),
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

    // 3. Final Form State: (AI Verified or Manual Override)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_image!, height: 180, width: double.infinity, fit: BoxFit.cover)),
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