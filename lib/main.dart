import 'package:banjir_beacon/screens/login_screen.dart';
import 'package:banjir_beacon/screens/main_screen.dart';
import 'package:banjir_beacon/screens/map_screen.dart';
import 'package:banjir_beacon/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/gradient_scaffold.dart'; 
import 'package:banjir_beacon/screens/info_screen.dart';
import 'package:firebase_core/firebase_core.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 

  runApp(const MyApp());
}


// 1. THE MANAGER
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
      home: const LoginScreen(), 
     );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Banjir Beacon', style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        backgroundColor: Colors.transparent, 
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
