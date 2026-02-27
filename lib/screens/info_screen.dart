import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/gradient_scaffold.dart'; 
import 'calling_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  // Function to open a map location
  Future<void> _openMap(String locationQuery) async {
    // Note: In a real app, we'd use a proper Google Maps URL
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$locationQuery');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Emergency Info Hub', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        children: [
          _buildSectionHeader('Nearby Shelters (PPS)'),
          _buildInfoCard(
            'Dewan Orang Ramai Kuantan', 
            'Status: Open - 85% Full', 
            Icons.home_work_rounded,
            Colors.blue,
            'Dewan+Orang+Ramai+Kuantan',
          ),
          _buildInfoCard(
            'SK Bukit Sekilau', 
            'Status: Open - 40% Full', 
            Icons.school_rounded,
            Colors.green,
            'SK+Bukit+Sekilau+Kuantan',
          ),
          
          const SizedBox(height: 30),
          
          _buildSectionHeader('Emergency Contacts'),
          // NOTICE: We are now passing 'context' as the first argument!
          _buildContactCard(context, 'Bomba (Fire Dept)', '994', Colors.red),
          _buildContactCard(context, 'Civil Defence (APM)', '999', Colors.orange),
          _buildContactCard(context, 'Police (PDRM)', '999', Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(title, 
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
    );
  }

  Widget _buildInfoCard(String name, String status, IconData icon, Color iconColor, String mapQuery) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status),
        trailing: const Icon(Icons.map_outlined, color: Colors.blue),
        onTap: () => _openMap(mapQuery), 
      ),
    );
  }

  // ADDED 'BuildContext context' to the parameters here
  Widget _buildContactCard(BuildContext context, String agency, String number, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(agency, 
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Tap to call: $number'),
        trailing: Icon(Icons.phone_forwarded, color: color),
        onTap: () {
          // Now 'context' works because we passed it in!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallingScreen(
                agencyName: agency,
                phoneNumber: number,
              ),
            ),
          );
        },
      ),
    );
  }
}