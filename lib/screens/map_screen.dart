import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/gradient_scaffold.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _selectedMapType = 'normal';
  bool _showLegend = false;
  bool _mapInitialized = false;
  String? _errorMessage;
  
  // Predefined locations in Kuantan for demo
  final List<Map<String, dynamic>> _dummyReports = [
    {
      'id': '1',
      'lat': 3.8167,
      'lng': 103.3317,
      'title': 'Severe Flooding',
      'snippet': 'Water level: 1.5m - Do not pass',
      'severity': 'high',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'verified': true,
    },
    {
      'id': '2',
      'lat': 3.8267,
      'lng': 103.3417,
      'title': 'Moderate Flooding',
      'snippet': 'Water level: 0.8m - Pass with caution',
      'severity': 'medium',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'verified': true,
    },
    {
      'id': '3',
      'lat': 3.8067,
      'lng': 103.3217,
      'title': 'Evacuation Center',
      'snippet': 'Dewan Orang Ramai Kuantan - Open for evacuees',
      'severity': 'shelter',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'verified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Try to get current location
      try {
        final position = await _getCurrentLocation();
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        // Default to Kuantan if location fails
        setState(() {
          _currentPosition = const LatLng(3.8167, 103.3317);
        });
      }
      
      // Add dummy markers
      _addDummyMarkers();
      
      setState(() {
        _isLoading = false;
        _mapInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize map: $e';
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Return default position instead of throwing
      return Position(
        latitude: 3.8167,
        longitude: 103.3317,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Return default position
        return Position(
          latitude: 3.8167,
          longitude: 103.3317,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Return default position
      return Position(
        latitude: 3.8167,
        longitude: 103.3317,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  void _addDummyMarkers() {
    setState(() {
      for (var report in _dummyReports) {
        _markers.add(_createMarkerFromReport(report));
      }
    });
  }

  Marker _createMarkerFromReport(Map<String, dynamic> report) {
    BitmapDescriptor markerIcon;
    
    // Set marker icon based on severity
    switch (report['severity']) {
      case 'high':
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        break;
      case 'medium':
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        break;
      case 'low':
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
        break;
      case 'shelter':
        markerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        break;
      default:
        markerIcon = BitmapDescriptor.defaultMarker;
    }

    return Marker(
      markerId: MarkerId(report['id']),
      position: LatLng(report['lat'], report['lng']),
      infoWindow: InfoWindow(
        title: report['title'],
        snippet: report['snippet'],
      ),
      icon: markerIcon,
      onTap: () => _showReportDetails(report),
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
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
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: report['severity'] == 'high' ? Colors.red :
                           report['severity'] == 'medium' ? Colors.orange :
                           report['severity'] == 'low' ? Colors.yellow :
                           Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(report['snippet']),
            const SizedBox(height: 8),
            Text(
              'Reported: ${_getTimeAgo(report['timestamp'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (report['verified'] == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.blue, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Verified by AI',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(LatLng(report['lat'], report['lng'])),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View on Map'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _shareReport(report);
                    },
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _shareReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: ${report['title']}')),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
      _mapInitialized = true;
    });
  }

  void _changeMapType(String type) {
    setState(() {
      _selectedMapType = type;
      MapType mapType;
      
      switch (type) {
        case 'satellite':
          mapType = MapType.satellite;
          break;
        case 'hybrid':
          mapType = MapType.hybrid;
          break;
        case 'terrain':
          mapType = MapType.terrain;
          break;
        default:
          mapType = MapType.normal;
      }
      
      _mapController?.setMapType(mapType);
    });
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Type',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMapTypeOption('Normal', 'normal', Icons.map),
            _buildMapTypeOption('Satellite', 'satellite', Icons.satellite),
            _buildMapTypeOption('Hybrid', 'hybrid', Icons.layers),
            _buildMapTypeOption('Terrain', 'terrain', Icons.terrain),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTypeOption(String title, String value, IconData icon) {
    bool isSelected = _selectedMapType == value;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[700],
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: () {
          _changeMapType(value);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(
          'Flood Risk Map',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers, color: Colors.black),
            onPressed: _showMapTypeSelector,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              setState(() => _showLegend = !_showLegend);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading map',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeMap,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_currentPosition != null)
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              compassEnabled: true,
              trafficEnabled: true,
              mapToolbarEnabled: true,
              onTap: (latLng) {
                _showAddReportDialog(latLng);
              },
            ),
          
          // Legend overlay
          if (_showLegend)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.red, 'Severe Flood (High Risk)'),
                    _buildLegendItem(Colors.orange, 'Moderate Flood'),
                    _buildLegendItem(Colors.yellow, 'Minor Flood'),
                    _buildLegendItem(Colors.green, 'Evacuation Center'),
                    const Divider(),
                    _buildLegendItem(Colors.purple, 'Purple Zone (High Risk Area)'),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 4,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        const Text('Safe Route'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Quick report button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showQuickReportDialog();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Quick Report Flood',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddReportDialog(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Flood Here?'),
        content: Text('Lat: ${position.latitude.toStringAsFixed(4)}\nLng: ${position.longitude.toStringAsFixed(4)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to Report Screen')),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _showQuickReportDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.orange),
              title: const Text('Rising Water'),
              subtitle: const Text('Water level increasing slowly'),
              onTap: () => _submitQuickReport('rising'),
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: const Text('Severe Flood'),
              subtitle: const Text('Deep water, dangerous conditions'),
              onTap: () => _submitQuickReport('severe'),
            ),
            ListTile(
              leading: const Icon(Icons.safety_check, color: Colors.green),
              title: const Text('Safe Area'),
              subtitle: const Text('Area is dry and passable'),
              onTap: () => _submitQuickReport('safe'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitQuickReport(String type) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick report submitted: $type'),
        backgroundColor: Colors.green,
      ),
    );
    print('Quick report: $type at position: $_currentPosition');
  }
}

extension on GoogleMapController? {
  void setMapType(MapType mapType) {}
}