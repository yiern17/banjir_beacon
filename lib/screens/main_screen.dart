import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'report_screen.dart';
import 'info_screen.dart';
import 'setting_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of the screens you already created
  final List<Widget> _screens = [
    const InfoScreen(),     // Index 0
    const ReportScreen(),  // Index 1
    const InfoScreen(),    // Index 2
    const SettingScreen(), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Shows the active screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Changes the screen when tapped
          });
        },
        type: BottomNavigationBarType.fixed, // Keeps all icons visible
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'Info'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}