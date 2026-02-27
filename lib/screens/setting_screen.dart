import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_scaffold.dart';
import 'login_screen.dart'; 

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // -------------------------------------------------------------
  // POPUP 1: Edit Phone Number
  // -------------------------------------------------------------
  Future<void> _showEditPhoneDialog(String currentPhone) async {
    final TextEditingController phoneController = TextEditingController(text: currentPhone);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Phone Number"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "New Phone Number",
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (phoneController.text.trim().isNotEmpty && currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .update({'phone': phoneController.text.trim()});
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Phone number updated!"), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text("SAVE"),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // POPUP 2: Edit Medical / Special Needs
  // -------------------------------------------------------------
  Future<void> _showEditMedicalDialog(String currentMedical) async {
    // If it currently says "None specified", start with an empty text box
    final initialText = currentMedical == 'None specified' ? '' : currentMedical;
    final TextEditingController medicalController = TextEditingController(text: initialText);

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Medical / Special Needs"),
          content: TextField(
            controller: medicalController,
            maxLines: 3, // Gives them more space to type details
            decoration: const InputDecoration(
              hintText: "e.g., Asthma patient, wheelchair user, diabetic...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (currentUser != null) {
                  // If they clear the box, set it back to "None specified"
                  String newText = medicalController.text.trim();
                  if (newText.isEmpty) newText = 'None specified';

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .update({'medicalInfo': newText});
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Medical info updated!"), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text("SAVE"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text("No user logged in."));
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Error loading profile data."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String name = userData['name'] ?? 'Unknown User';
          String email = userData['email'] ?? currentUser!.email ?? 'No Email';
          String phone = userData['phone'] ?? 'No Phone Number';
          
          // Pulls the medical info, or defaults to "None specified" if they haven't set it yet
          String medicalInfo = userData['medicalInfo'] ?? 'None specified';

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // --- PROFILE CARD ---
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              _buildSectionHeader("Contact Information"),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text("Phone Number"),
                  subtitle: Text(phone, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditPhoneDialog(phone),
                  ),
                ),
              ),

              _buildSectionHeader("Emergency Rescue Details"),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.medical_information, color: Colors.red),
                  title: const Text("Medical / Special Needs"),
                  // Shows the actual medical data from Firestore
                  subtitle: Text(medicalInfo, style: const TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditMedicalDialog(medicalInfo),
                  ),
                ),
              ),

              _buildSectionHeader("App Settings"),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.location_on, color: Colors.blue),
                      title: const Text("Emergency Location Sharing"),
                      subtitle: const Text("Allow rescuers to see your GPS"),
                      value: true, 
                      onChanged: (bool value) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active, color: Colors.amber),
                      title: const Text("Flood Warning Alerts"),
                      value: true,
                      onChanged: (bool value) {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- LOGOUT BUTTON ---
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("SIGN OUT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}