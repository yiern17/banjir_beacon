import 'dart:async';
import 'package:flutter/material.dart';

class CallingScreen extends StatefulWidget {
  final String agencyName;
  final String phoneNumber;

  const CallingScreen({
    super.key, 
    required this.agencyName, 
    required this.phoneNumber
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Dark emergency theme
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              const SizedBox(height: 50),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                widget.agencyName,
                style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _seconds == 0 ? "Calling..." : _formatTime(_seconds),
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ],
          ),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCallAction(Icons.mic_off, "Mute"),
              const SizedBox(width: 40),
              _buildCallAction(Icons.dialpad, "Keypad"),
              const SizedBox(width: 40),
              _buildCallAction(Icons.volume_up, "Speaker"),
            ],
          ),

          // End Call Button
          FloatingActionButton.large(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.red,
            child: const Icon(Icons.call_end, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCallAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white54)),
      ],
    );
  }
}