import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/gradiend_scaffold.dart'; // Import the GradientScaffold widget

void main() {
  runApp(const MyApp());
}

// 1. THE MANAGER (Do not change this)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banjir Beacon',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(), 
      ),
      // It tells the app to load HomeScreen
      home: const HomeScreen(), 
    );
  }
}

// 2. THE SCREEN (We use GradientScaffold here!)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- LOOK HERE: We replaced "Scaffold" with "GradientScaffold" ---
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Banjir Beacon', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        backgroundColor: Colors.transparent, // Make it transparent to see the gradient!
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Emergency Alert',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ), 
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("Reporting flood...");
              },
              child: const Text('Report Flood'),
            ),
          ],
        ),
      ),
    );
  }
}
