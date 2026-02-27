import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:banjir_beacon/services/gemini_service.dart';
import '../widgets/gradient_scaffold.dart'; // Import your custom scaffold

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  XFile? _imageFile; 
  bool _isAnalyzing = false;
  bool _isSubmitting = false; 
  bool _manualMode = false;
  bool _aiSuccess = false; 
  String _severity = "LOW";
  final TextEditingController _descController = TextEditingController();

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final XFile? photo = await ImagePicker().pickImage(source: source);
    if (photo == null) return;

    setState(() {
      _imageFile = photo; 
      _isAnalyzing = true;
      _manualMode = false;
      _aiSuccess = false;
    });

    final result = await GeminiService.analyzeFloodImage(_imageFile!);

    setState(() {
      _isAnalyzing = false;
      
      if (result['description']!.contains('AI could not verify') || 
          result['description']!.contains('AI connection error')) {
        _aiSuccess = false;
        _manualMode = false; 
      } else {
        _aiSuccess = true;
        _severity = result['severity']!;
        _descController.text = result['description']!;
        _manualMode = false; 
      }
    });
  }

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      const double lat = 3.8126;
      const double lng = 103.3256;

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user?.uid ?? 'anonymous',
        'severity': _severity,
        'description': _descController.text.trim(),
        'location': const GeoPoint(lat, lng), 
        'status': 'pending', 
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency Report Sent!"), backgroundColor: Colors.green)
        );
        setState(() {
          _imageFile = null;
          _descController.clear();
          _severity = "LOW";
          _manualMode = false;
          _aiSuccess = false;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to send report."), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrapped in GradientScaffold to match your other screens
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          "Emergency Report", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ), 
        //leading: const CloseButton(color: Colors.black),
        backgroundColor: Colors.transparent, // Match InfoScreen style
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isAnalyzing 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(), 
                SizedBox(height: 16), 
                Text("AI Verifying Hazard...", style: TextStyle(fontWeight: FontWeight.bold))
              ],
            ))
          : SingleChildScrollView(child: _buildUI()),
      ),
    );
  }

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
          const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.blueGrey),
          const SizedBox(height: 20),
          const Text("Upload a photo to report a flood hazard.", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            onPressed: () => _pickAndAnalyze(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55), 
              backgroundColor: Colors.redAccent, 
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text("TAKE PHOTO", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_library),
            onPressed: () => _pickAndAnalyze(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              side: const BorderSide(color: Colors.blueGrey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text("UPLOAD FROM GALLERY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
        ],
      );
    }

    if (!_aiSuccess && !_manualMode) {
      return Column(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: _displayImage(200)),
          const SizedBox(height: 20),
          const Text("AI could not verify this as a flood.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() => _imageFile = null), 
            child: const Text("RETAKE PHOTO")
          ),
          TextButton(
            onPressed: () => setState(() {
              _manualMode = true;
              _descController.clear(); 
            }), 
            child: const Text("I'M SURE IT'S A FLOOD (REPORT MANUALLY)")
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: _displayImage(180)),
        const SizedBox(height: 20),
        
        if (_aiSuccess && !_manualMode) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Semi-transparent white to pop on the gradient
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text("AI Detected Level: $_severity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(_descController.text, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _manualMode = true),
              child: const Text("Edit details manually", style: TextStyle(color: Colors.blueGrey)),
            ),
          ),
        ] else ...[
          const Text("Severity Level", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _severity,
            items: ["LOW", "MODERATE", "SEVERE"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => _severity = v!),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController, 
            maxLines: 3, 
            decoration: InputDecoration(
              hintText: "Enter details manually...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
            )
          ),
        ],

        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 55), 
            backgroundColor: const Color(0xFF2C3E50), // Dark color matching your Info screen text
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}


// import 'dart:io';
// import 'package:flutter/foundation.dart'; 
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:banjir_beacon/services/gemini_service.dart';

// class ReportScreen extends StatefulWidget {
//   const ReportScreen({super.key});
//   @override
//   State<ReportScreen> createState() => _ReportScreenState();
// }

// class _ReportScreenState extends State<ReportScreen> {
//   XFile? _imageFile; 
//   bool _isAnalyzing = false;
//   bool _isSubmitting = false; 
//   bool _manualMode = false;
//   bool _aiSuccess = false; // NEW: Tracks if AI understood the image
//   String _severity = "LOW";
//   final TextEditingController _descController = TextEditingController();

//   Future<void> _pickAndAnalyze(ImageSource source) async {
//     final XFile? photo = await ImagePicker().pickImage(source: source);
//     if (photo == null) return;

//     setState(() {
//       _imageFile = photo; 
//       _isAnalyzing = true;
//       _manualMode = false;
//       _aiSuccess = false;
//     });

//     final result = await GeminiService.analyzeFloodImage(_imageFile!);

//     setState(() {
//       _isAnalyzing = false;
      
//       // Check if the AI returned our specific error messages
//       if (result['description']!.contains('AI could not verify') || 
//           result['description']!.contains('AI connection error')) {
//         _aiSuccess = false;
//         _manualMode = false; // We wait for them to click the manual button
//       } else {
//         // AI Success!
//         _aiSuccess = true;
//         _severity = result['severity']!;
//         _descController.text = result['description']!;
//         _manualMode = false; 
//       }
//     });
//   }

//   Future<void> _submitReport() async {
//     setState(() {
//       _isSubmitting = true;
//     });

//     try {
//       final User? user = FirebaseAuth.instance.currentUser;
      
//       // Hardcoded Kuantan coordinates for the hackathon MVP
//       const double lat = 3.8126;
//       const double lng = 103.3256;

//       await FirebaseFirestore.instance.collection('reports').add({
//         'userId': user?.uid ?? 'anonymous',
//         'severity': _severity,
//         'description': _descController.text.trim(),
//         'location': const GeoPoint(lat, lng), 
//         'status': 'pending', 
//         'timestamp': FieldValue.serverTimestamp(),
//       });

//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Emergency Report Sent!"), backgroundColor: Colors.green)
//         );
//         setState(() {
//           _imageFile = null;
//           _descController.clear();
//           _severity = "LOW";
//           _manualMode = false;
//           _aiSuccess = false;
//         });
//       }
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to send report."), backgroundColor: Colors.red)
//         );
//       }
//     } finally {
//       if (context.mounted) {
//         setState(() {
//           _isSubmitting = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Emergency Report"), leading: const CloseButton()),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: _isAnalyzing 
//           ? const Center(child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [CircularProgressIndicator(), SizedBox(height: 16), Text("AI Verifying Hazard...")],
//             ))
//           : SingleChildScrollView(child: _buildUI()),
//       ),
//     );
//   }

//   Widget _displayImage(double height) {
//     if (kIsWeb) {
//       return Image.network(_imageFile!.path, height: height, width: double.infinity, fit: BoxFit.cover);
//     } else {
//       return Image.file(File(_imageFile!.path), height: height, width: double.infinity, fit: BoxFit.cover, cacheHeight: 400);
//     }
//   }

//   Widget _buildUI() {
//     // STATE 1: No Image Selected
//     if (_imageFile == null) {
//       return Column(
//         children: [
//           const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.blueGrey),
//           const SizedBox(height: 20),
//           const Text("Upload a photo to report a flood hazard.", style: TextStyle(fontSize: 16)),
//           const SizedBox(height: 40),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.camera_alt),
//             onPressed: () => _pickAndAnalyze(ImageSource.camera),
//             style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
//             label: const Text("TAKE PHOTO", style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//           const SizedBox(height: 16),
//           OutlinedButton.icon(
//             icon: const Icon(Icons.photo_library),
//             onPressed: () => _pickAndAnalyze(ImageSource.gallery),
//             style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
//             label: const Text("UPLOAD FROM GALLERY", style: TextStyle(fontWeight: FontWeight.bold)),
//           ),
//         ],
//       );
//     }

//     // STATE 2: AI Failed (Show the manual button)
//     if (!_aiSuccess && !_manualMode) {
//       return Column(
//         children: [
//           _displayImage(200),
//           const SizedBox(height: 20),
//           const Text("AI could not verify this as a flood.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: () => setState(() => _imageFile = null), 
//             child: const Text("RETAKE PHOTO")
//           ),
//           TextButton(
//             onPressed: () => setState(() {
//               _manualMode = true;
//               _descController.clear(); // Clear the AI error message
//             }), 
//             child: const Text("I'M SURE IT'S A FLOOD (REPORT MANUALLY)")
//           ),
//         ],
//       );
//     }

//     // STATE 3: AI Succeeded OR User Clicked Manual Mode
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         ClipRRect(borderRadius: BorderRadius.circular(12), child: _displayImage(180)),
//         const SizedBox(height: 20),
        
//         // --- DYNAMIC UI: Read-Only Box vs Editable Form ---
//         if (_aiSuccess && !_manualMode) ...[
//           // Show beautiful Read-Only AI Results
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.blue.shade200)
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.verified, color: Colors.blue),
//                     const SizedBox(width: 8),
//                     Text("AI Detected Level: $_severity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Text(_descController.text, style: const TextStyle(fontSize: 15)),
//               ],
//             ),
//           ),
//           // Small button just in case the AI made a mistake
//           Align(
//             alignment: Alignment.centerRight,
//             child: TextButton(
//               onPressed: () => setState(() => _manualMode = true),
//               child: const Text("Edit details manually"),
//             ),
//           ),
//         ] else ...[
//           // Show Manual Dropdown & TextField
//           const Text("Severity Level", style: TextStyle(fontWeight: FontWeight.bold)),
//           DropdownButtonFormField<String>(
//             value: _severity,
//             items: ["LOW", "MODERATE", "SEVERE"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
//             onChanged: (v) => setState(() => _severity = v!),
//             decoration: const InputDecoration(border: OutlineInputBorder()),
//           ),
//           const SizedBox(height: 20),
          
//           const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
//           TextField(
//             controller: _descController, 
//             maxLines: 3, 
//             decoration: const InputDecoration(
//               hintText: "Enter details manually...",
//               border: OutlineInputBorder()
//             )
//           ),
//         ],
//         // --------------------------------------------------

//         const SizedBox(height: 30),
//         ElevatedButton(
//           onPressed: _isSubmitting ? null : _submitReport,
//           style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.blue[900]),
//           child: _isSubmitting 
//               ? const CircularProgressIndicator(color: Colors.white)
//               : const Text("SUBMIT REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         ),
//       ],
//     );
//   }
// }