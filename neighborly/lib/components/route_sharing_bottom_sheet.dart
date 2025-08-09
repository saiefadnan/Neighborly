import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:neighborly/components/shared_routes_bottom_sheet.dart';

class RouteSharingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> helpData;
  final LatLng userLocation;

  const RouteSharingBottomSheet({
    super.key,
    required this.helpData,
    required this.userLocation,
  });

  @override
  State<RouteSharingBottomSheet> createState() =>
      _RouteSharingBottomSheetState();
}

class _RouteSharingBottomSheetState extends State<RouteSharingBottomSheet> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];
  final List<Map<String, dynamic>> _waypoints = [];
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();
  bool _isDrawingMode = false;
  bool _showInstructions = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    // Add start and destination markers
    final destination = widget.helpData['location'] as LatLng;

    _markers.addAll({
      Marker(
        markerId: const MarkerId('start'),
        position: widget.userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Start Point',
        ),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.helpData['address'] ?? 'End Point',
        ),
      ),
    });

    // Add initial route points
    _routePoints.addAll([widget.userLocation, destination]);
  }

  void _onMapTap(LatLng position) {
    if (_isDrawingMode) {
      setState(() {
        // Insert new point before destination
        _routePoints.insert(_routePoints.length - 1, position);
        _updateRoutePolyline();
        _addWaypointMarker(position, _routePoints.length - 2);
      });
    }
  }

  void _addWaypointMarker(LatLng position, int index) {
    final markerId = MarkerId('waypoint_$index');
    final marker = Marker(
      markerId: markerId,
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: 'Waypoint ${index}',
        snippet: 'Tap to add instructions',
        onTap: () => _showWaypointDialog(index, position),
      ),
    );

    _markers.add(marker);

    // Add to waypoints list if not already exists
    if (_waypoints.length <= index) {
      _waypoints.add({
        'position': position,
        'instruction': 'Continue straight',
        'landmark': '',
      });
    }
  }

  void _updateRoutePolyline() {
    _polylines.clear();

    if (_routePoints.length >= 2) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: const Color(0xFF71BB7B),
          width: 5,
          patterns: [],
        ),
      );
    }
  }

  void _showWaypointDialog(int index, LatLng position) {
    final instructionController = TextEditingController();
    final landmarkController = TextEditingController();

    if (index < _waypoints.length) {
      instructionController.text = _waypoints[index]['instruction'] ?? '';
      landmarkController.text = _waypoints[index]['landmark'] ?? '';
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Waypoint ${index + 1} Instructions'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: instructionController,
                  decoration: const InputDecoration(
                    labelText: 'Direction Instructions',
                    hintText: 'e.g., Turn right after the mosque',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Nearby Landmark',
                    hintText: 'e.g., City Bank, Dhaka College',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (index < _waypoints.length) {
                      _waypoints[index]['instruction'] =
                          instructionController.text;
                      _waypoints[index]['landmark'] = landmarkController.text;
                    } else {
                      _waypoints.add({
                        'position': position,
                        'instruction': instructionController.text,
                        'landmark': landmarkController.text,
                      });
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
    });
  }

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _routePoints.addAll([
        widget.userLocation,
        widget.helpData['location'] as LatLng,
      ]);
      _waypoints.clear();
      _polylines.clear();

      // Keep only start and destination markers
      _markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('waypoint_'),
      );
    });
  }

  void _shareRoute() {
    if (_routePoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one route point')),
      );
      return;
    }

    // Show route sharing confirmation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Share Route'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _routeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Route Name',
                    hintText: 'e.g., Best route avoiding traffic',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This route has ${_routePoints.length} points and ${_waypoints.length} waypoints with instructions.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _submitRoute();
                  Navigator.pop(context);
                  Navigator.pop(context); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Share Route'),
              ),
            ],
          ),
    );
  }

  void _submitRoute() {
    // Here you would normally send this to your backend
    final routeData = {
      'name':
          _routeNameController.text.isEmpty
              ? 'Suggested Route'
              : _routeNameController.text,
      'points':
          _routePoints
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
      'waypoints': _waypoints,
      'helpRequestId': widget.helpData['id'] ?? 'temp_id',
      'helper': 'Current User', // Replace with actual user
      'createdAt': DateTime.now().toIso8601String(),
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Route "${routeData['name']}" shared successfully!'),
        backgroundColor: const Color(0xFF71BB7B),
      ),
    );
  }

  void _openInOSM() {
    final destination = widget.helpData['location'] as LatLng;
    final osmUrl = Uri.parse(
      'https://www.openstreetmap.org/directions?from=${widget.userLocation.latitude},${widget.userLocation.longitude}&to=${destination.latitude},${destination.longitude}',
    );

    launchUrl(osmUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button dismissal
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Handle bar - only this area allows dismissal
            GestureDetector(
              onPanUpdate: (details) {
                // Only allow dismissal if dragging down
                if (details.delta.dy > 0) {
                  Navigator.pop(context);
                }
              },
              child: Container(
                width: double.infinity, // Make the entire top area draggable
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Color(0xFF71BB7B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Help with Route',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Draw the best route for ${widget.helpData['username'] ?? 'this person'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleDrawingMode,
                      icon: Icon(_isDrawingMode ? Icons.stop : Icons.edit_road),
                      label: Text(
                        _isDrawingMode ? 'Stop Drawing' : 'Draw Route',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isDrawingMode
                                ? Colors.red
                                : const Color(0xFF71BB7B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        isDismissible:
                            false, // Prevent dismissal by tapping outside
                        enableDrag: false, // Prevent drag to dismiss
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder:
                            (context) => SharedRoutesBottomSheet(
                              helpData: widget.helpData,
                              userLocation: widget.userLocation,
                            ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('View Routes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _clearRoute,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear Route',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                  IconButton(
                    onPressed: _openInOSM,
                    icon: const Icon(Icons.map),
                    tooltip: 'Open in OpenStreetMap',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue[100],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap map to add waypoints',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            if (_isDrawingMode)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap on the map to add waypoints along your recommended route',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),

            // Map
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        (widget.userLocation.latitude +
                                (widget.helpData['location'] as LatLng)
                                    .latitude) /
                            2,
                        (widget.userLocation.longitude +
                                (widget.helpData['location'] as LatLng)
                                    .longitude) /
                            2,
                      ),
                      zoom: 13,
                    ),
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (controller) {
                      // Map controller ready
                    },
                    onTap: _onMapTap,
                    mapType: MapType.normal,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                  ),
                ),
              ),
            ),

            // Instructions section
            if (_waypoints.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.list,
                          color: Color(0xFF71BB7B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Route Instructions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed:
                              () => setState(
                                () => _showInstructions = !_showInstructions,
                              ),
                          child: Text(_showInstructions ? 'Hide' : 'Show'),
                        ),
                      ],
                    ),
                    if (_showInstructions)
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: _waypoints.length,
                          itemBuilder: (context, index) {
                            final waypoint = _waypoints[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${waypoint['instruction']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (waypoint['landmark'].isNotEmpty)
                                    Text(
                                      'Near: ${waypoint['landmark']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            // Share button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareRoute,
                  icon: const Icon(Icons.share),
                  label: const Text('Share This Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _instructionController.dispose();
    super.dispose();
  }
}
