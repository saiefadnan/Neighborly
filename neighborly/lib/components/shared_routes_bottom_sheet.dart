import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedRoutesBottomSheet extends StatefulWidget {
  final Map<String, dynamic> helpData;
  final LatLng userLocation;

  const SharedRoutesBottomSheet({
    super.key,
    required this.helpData,
    required this.userLocation,
  });

  @override
  State<SharedRoutesBottomSheet> createState() =>
      _SharedRoutesBottomSheetState();
}

class _SharedRoutesBottomSheetState extends State<SharedRoutesBottomSheet> {
  // Sample shared routes data (in real app, this would come from backend)
  final List<Map<String, dynamic>> sharedRoutes = [
    {
      'id': '1',
      'name': 'Avoid Traffic Route',
      'helper': 'Karim Rahman',
      'helperRating': 4.8,
      'createdAt': '2 hours ago',
      'estimatedTime': '35 min',
      'description': 'Best route during rush hour, avoids major intersections',
      'waypoints': [
        {
          'instruction': 'Head north on Mirpur Road',
          'landmark': 'Near Dhanmondi 27',
        },
        {
          'instruction': 'Turn right after City Bank',
          'landmark': 'City Bank ATM',
        },
        {
          'instruction': 'Continue straight until you see the lake',
          'landmark': 'Dhanmondi Lake',
        },
      ],
      'likes': 12,
      'isLiked': false,
    },
    {
      'id': '2',
      'name': 'Scenic Route',
      'helper': 'Sarah Ahmed',
      'helperRating': 4.9,
      'createdAt': '4 hours ago',
      'estimatedTime': '42 min',
      'description': 'Beautiful route through Ramna Park, longer but peaceful',
      'waypoints': [
        {
          'instruction': 'Take Science Lab Road',
          'landmark': 'Science Lab Bus Stop',
        },
        {'instruction': 'Enter Ramna Park area', 'landmark': 'Ramna Park Gate'},
        {'instruction': 'Exit near Shahbagh', 'landmark': 'Shahbagh Square'},
      ],
      'likes': 8,
      'isLiked': true,
    },
  ];

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _selectedRouteIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _showRoute(_selectedRouteIndex);
  }

  void _initializeMarkers() {
    final destination = widget.helpData['location'] as LatLng;

    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: widget.userLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: widget.helpData['address'] ?? 'Target Location',
        ),
      ),
    };
  }

  void _showRoute(int routeIndex) {
    setState(() {
      _selectedRouteIndex = routeIndex;
      _polylines.clear();

      // Create sample polyline (in real app, this would use actual route points)
      final destination = widget.helpData['location'] as LatLng;
      final routeColor = routeIndex == 0 ? Colors.blue : Colors.purple;

      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$routeIndex'),
          points: [widget.userLocation, destination],
          color: routeColor,
          width: 4,
        ),
      );
    });
  }

  void _toggleLike(int routeIndex) {
    setState(() {
      final route = sharedRoutes[routeIndex];
      route['isLiked'] = !route['isLiked'];
      route['likes'] += route['isLiked'] ? 1 : -1;
    });
  }

  Future<void> _openInMaps(Map<String, dynamic> route) async {
    final destination = widget.helpData['location'] as LatLng;
    final osmUrl = Uri.parse(
      'https://www.openstreetmap.org/directions?from=${widget.userLocation.latitude},${widget.userLocation.longitude}&to=${destination.latitude},${destination.longitude}',
    );

    if (await canLaunchUrl(osmUrl)) {
      await launchUrl(osmUrl, mode: LaunchMode.externalApplication);
    }
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.route,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shared Routes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Routes shared by helpful neighbors',
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

            // Map preview
            Container(
              height: 200,
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
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    // Map controller ready
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                ),
              ),
            ),

            // Routes list
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Routes (${sharedRoutes.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sharedRoutes.length,
                        itemBuilder: (context, index) {
                          final route = sharedRoutes[index];
                          final isSelected = index == _selectedRouteIndex;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? Colors.blue
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _showRoute(index),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Route header
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  route['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      route['helper'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Icon(
                                                      Icons.star,
                                                      size: 14,
                                                      color: Colors.amber,
                                                    ),
                                                    Text(
                                                      '${route['helperRating']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  route['estimatedTime'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                route['createdAt'],
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Description
                                      Text(
                                        route['description'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // Waypoints preview
                                      Text(
                                        'Key Points:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...route['waypoints']
                                          .take(2)
                                          .map<Widget>(
                                            (waypoint) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 2,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.circle,
                                                    size: 6,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      waypoint['instruction'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),

                                      const SizedBox(height: 12),

                                      // Actions
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _toggleLike(index),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  route['isLiked']
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  size: 16,
                                                  color:
                                                      route['isLiked']
                                                          ? Colors.red
                                                          : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${route['likes']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          InkWell(
                                            onTap: () => _openInMaps(route),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.map,
                                                  size: 16,
                                                  color: Colors.blue[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Open in Maps',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          if (isSelected)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Viewing',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blue[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
