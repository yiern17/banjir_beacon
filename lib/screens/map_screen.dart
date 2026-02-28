import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_scaffold.dart';
import 'report_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _kuantanCenter = LatLng(3.8126, 103.3256);
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  MapType _currentMapType = MapType.normal;
  bool _showLegend = false;

  
  final List<Map<String, dynamic>> _hardcodedShelters = [
    {
      'id': 'shelter_1',
      'name': 'Dewan Orang Ramai Kuantan',
      'lat': 3.8067,
      'lng': 103.3217,
    },
    {
      'id': 'shelter_2',
      'name': 'SK Bukit Sekilau Shelter',
      'lat': 3.8190,
      'lng': 103.3250,
    },
  ];

  
  Future<void> syncHardcodedSheltersToFirestore() async {
    final collection = FirebaseFirestore.instance.collection('shelters');
    
    for (var s in _hardcodedShelters) {
      await collection.doc(s['id']).set({
        'name': s['name'],
        'location': GeoPoint(s['lat'], s['lng']),
        'address': s['address'],
        'type': 'OFFICIAL_SHELTER',
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAllMarkers(); 
  }

  
  void _loadAllMarkers() {
    // Stream 1: Flood Reports
    FirebaseFirestore.instance.collection('reports').snapshots().listen((reportSnapshot) {
      if (!mounted) return;

      // Stream 2: Database Shelters
      FirebaseFirestore.instance.collection('shelters').snapshots().listen((shelterSnapshot) {
        if (!mounted) return;

        setState(() {
          _markers.clear();

          // A. ADD FLOOD REPORTS (Red/Orange/Yellow)
          for (var doc in reportSnapshot.docs) {
            final data = doc.data();
            final GeoPoint geoPoint = data['location'];
            final String severity = data['severity'] ?? 'LOW';
            
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(geoPoint.latitude, geoPoint.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  severity == 'SEVERE' ? BitmapDescriptor.hueRed : 
                  severity == 'MODERATE' ? BitmapDescriptor.hueOrange : 
                  BitmapDescriptor.hueYellow
                ),
                onTap: () => _showReportDetails(data, doc.id),
              ),
            );
          }

          
          for (var doc in shelterSnapshot.docs) {
            final data = doc.data();
            final GeoPoint geoPoint = data['location'];
            _markers.add(_buildShelterMarker(doc.id, geoPoint.latitude, geoPoint.longitude, data['name'] ?? 'Shelter'));
          }

          
          for (var s in _hardcodedShelters) {
            _markers.add(_buildShelterMarker(s['id'], s['lat'], s['lng'], s['name']));
          }
        });
      });
    });
  }

  Marker _buildShelterMarker(String id, double lat, double lng, String name) {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: name, snippet: "Official Evacuation Center"),
    );
  }

  void _showReportDetails(Map<String, dynamic> data, String id) {
    final String severity = data['severity'] ?? 'LOW';
    final Timestamp? time = data['timestamp'] as Timestamp?;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: _getSeverityColor(severity)),
                const SizedBox(width: 8),
                Text("Flood Level: $severity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(data['description'] ?? 'No additional details provided.'),
            const SizedBox(height: 8),
            if (time != null)
              Text('Reported: ${_getTimeAgo(time.toDate())}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45), backgroundColor: Colors.blue),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Map Style', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildMapTypeOption('Normal', MapType.normal, Icons.map),
            _buildMapTypeOption('Satellite', MapType.satellite, Icons.satellite),
            _buildMapTypeOption('Hybrid', MapType.hybrid, Icons.layers),
            _buildMapTypeOption('Terrain', MapType.terrain, Icons.terrain),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, MapType type, IconData icon) {
    bool isSelected = _currentMapType == type;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.blue : Colors.black)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
      onTap: () {
        setState(() => _currentMapType = type);
        Navigator.pop(context);
      },
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  Color _getSeverityColor(String severity) {
    if (severity == 'SEVERE') return Colors.red;
    if (severity == 'MODERATE') return Colors.orange;
    return Colors.yellow.shade700;
  }

  Widget _buildMiniLegend() {
    return Positioned(
      top: 10, right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(Colors.red, 'Severe'),
            _buildLegendItem(Colors.orange, 'Moderate'),
            _buildLegendItem(Colors.yellow, 'Low'),
            _buildLegendItem(Colors.green, 'Shelter'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Banjir Beacon', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.layers, color: Colors.black), onPressed: _showMapTypeSelector),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back,", style: TextStyle(fontSize: 16, color: Colors.black54)),
                Text("Kuantan Safety Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(target: _kuantanCenter, zoom: 12),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: _markers,
                        mapType: _currentMapType,
                        myLocationEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                      Positioned(
                        bottom: 10, right: 10,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.info_outline, color: _showLegend ? Colors.blue : Colors.grey),
                          onPressed: () => setState(() => _showLegend = !_showLegend),
                        ),
                      ),
                      if (_showLegend) _buildMiniLegend(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportScreen())),
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text("QUICK REPORT FLOOD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}