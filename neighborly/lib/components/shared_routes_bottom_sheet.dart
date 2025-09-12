import 'package:flutter/material.dart';
import 'package:neighborly/services/map_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SharedRoutesBottomSheet extends StatefulWidget {
  final String helpRequestId;
  final bool isOwner; // True if current user is the help request owner
  final String ownerUserId; // User ID of the help request owner

  const SharedRoutesBottomSheet({
    super.key,
    required this.helpRequestId,
    required this.isOwner,
    required this.ownerUserId,
  });

  @override
  State<SharedRoutesBottomSheet> createState() => _SharedRoutesBottomSheetState();
}

class _SharedRoutesBottomSheetState extends State<SharedRoutesBottomSheet> {
  List<Map<String, dynamic>> routes = [];
  bool isLoading = true;
  String? error;
  bool showMapView = false; // Toggle between list and map view
  GoogleMapController? mapController;
  int selectedRouteIndex = 0; // Currently selected route for map view

  @override
  void initState() {
    super.initState();
    print('🗺️ SharedRoutesBottomSheet initialized');
    print('🗺️ Help request ID: "${widget.helpRequestId}"');
    print('🗺️ Is owner: ${widget.isOwner}');
    print('🗺️ Owner user ID: "${widget.ownerUserId}"');
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final result = await MapService.getRoutesForHelpRequest(widget.helpRequestId);
      
      if (result['success'] == true) {
        setState(() {
          routes = List<Map<String, dynamic>>.from(result['routes'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          error = result['message'] ?? 'Failed to load routes';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load routes: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _acceptRoute(String routeId, String creatorUserId) async {
    if (!widget.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the help request owner can accept routes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Accepting route...'),
            ],
          ),
        ),
      );

      final result = await MapService.acceptRoute(routeId);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route accepted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Close the bottom sheet
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept route: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting route: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoute(String routeId, String creatorUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != creatorUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only delete your own routes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: const Text('Are you sure you want to delete this route? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting route...'),
            ],
          ),
        ),
      );

      final result = await MapService.deleteRoute(routeId);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Route deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload routes
          await _loadRoutes();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete route: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting route: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Set<Marker> _generateMarkersForRoute(Map<String, dynamic> route) {
    final markers = <Marker>{};
    final waypoints = route['waypoints'] as List? ?? [];
    final routePoints = route['routePoints'] as List? ?? [];

    // Add start marker
    if (routePoints.isNotEmpty) {
      final startPoint = routePoints.first;
      markers.add(
        Marker(
          markerId: MarkerId('start_${route['id']}'),
          position: LatLng(
            startPoint['latitude']?.toDouble() ?? 0.0,
            startPoint['longitude']?.toDouble() ?? 0.0,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
    }

    // Add end marker
    if (routePoints.length > 1) {
      final endPoint = routePoints.last;
      markers.add(
        Marker(
          markerId: MarkerId('end_${route['id']}'),
          position: LatLng(
            endPoint['latitude']?.toDouble() ?? 0.0,
            endPoint['longitude']?.toDouble() ?? 0.0,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'End'),
        ),
      );
    }

    // Add waypoint markers
    for (int i = 0; i < waypoints.length; i++) {
      final waypoint = waypoints[i];
      final position = waypoint['position'];
      if (position != null) {
        markers.add(
          Marker(
            markerId: MarkerId('waypoint_${route['id']}_$i'),
            position: LatLng(
              position['latitude']?.toDouble() ?? 0.0,
              position['longitude']?.toDouble() ?? 0.0,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Waypoint ${i + 1}',
              snippet: waypoint['instruction'] ?? waypoint['landmark'] ?? '',
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _generatePolylinesForRoute(Map<String, dynamic> route) {
    final polylines = <Polyline>{};
    final routePoints = route['routePoints'] as List? ?? [];

    if (routePoints.length > 1) {
      final points = routePoints
          .map((point) => LatLng(
                point['latitude']?.toDouble() ?? 0.0,
                point['longitude']?.toDouble() ?? 0.0,
              ))
          .toList();

      polylines.add(
        Polyline(
          polylineId: PolylineId('route_${route['id']}'),
          points: points,
          color: Colors.blue,
          width: 4,
          patterns: [], // Solid line
        ),
      );
    }

    return polylines;
  }

  LatLng _getRouteCenter(Map<String, dynamic> route) {
    final routePoints = route['routePoints'] as List? ?? [];
    if (routePoints.isEmpty) {
      return const LatLng(0, 0); // Default fallback
    }

    double sumLat = 0;
    double sumLng = 0;
    for (final point in routePoints) {
      sumLat += point['latitude']?.toDouble() ?? 0.0;
      sumLng += point['longitude']?.toDouble() ?? 0.0;
    }

    return LatLng(sumLat / routePoints.length, sumLng / routePoints.length);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                        widget.isOwner 
                          ? 'Routes shared for your help request'
                          : 'Routes shared by community helpers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // View toggle buttons
                if (routes.isNotEmpty && !isLoading && error == null)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => setState(() => showMapView = false),
                        icon: Icon(
                          Icons.list,
                          color: !showMapView ? Colors.blue : Colors.grey,
                        ),
                        tooltip: 'List View',
                      ),
                      IconButton(
                        onPressed: () => setState(() => showMapView = true),
                        icon: Icon(
                          Icons.map,
                          color: showMapView ? Colors.blue : Colors.grey,
                        ),
                        tooltip: 'Map View',
                      ),
                    ],
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading routes...'),
                      ],
                    ),
                  )
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRoutes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : routes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.route_outlined,
                                  color: Colors.grey[400],
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No routes shared yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to share a helpful route!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : showMapView
                            ? _buildMapView()
                            : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (routes.isEmpty) return const SizedBox.shrink();

    final currentRoute = routes[selectedRouteIndex];
    final markers = _generateMarkersForRoute(currentRoute);
    final polylines = _generatePolylinesForRoute(currentRoute);
    final center = _getRouteCenter(currentRoute);

    return Column(
      children: [
        // Route selector
        if (routes.length > 1)
          Container(
            height: 50,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final isSelected = index == selectedRouteIndex;
                
                return GestureDetector(
                  onTap: () => setState(() => selectedRouteIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.route,
                          size: 16,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          route['routeName'] ?? route['title'] ?? 'Route ${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: 14.0,
            ),
            markers: markers,
            polylines: polylines,
            mapType: MapType.normal,
          ),
        ),

        // Route info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      currentRoute['routeName'] ?? currentRoute['title'] ?? 'Shared Route',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'by ${currentRoute['helperUsername'] ?? 'Anonymous'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (currentRoute['description'] != null && currentRoute['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  currentRoute['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildRouteActions(currentRoute),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        final currentUser = FirebaseAuth.instance.currentUser;
        final isMyRoute = currentUser?.uid == route['helperUserId'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route['routeName'] ?? route['title'] ?? 'Shared Route',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${route['helperUsername'] ?? 'Anonymous'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMyRoute)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Your Route',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Route description
                if (route['description'] != null && route['description'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      route['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Route details
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(route['createdAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (route['waypoints'] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(route['waypoints'] as List).length} waypoints',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Waypoints preview
                if (route['waypoints'] != null && (route['waypoints'] as List).isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route Instructions:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(route['waypoints'] as List).take(3).map<Widget>((waypoint) {
                        final instruction = waypoint['instruction'] ?? waypoint.toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 6, right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if ((route['waypoints'] as List).length > 3)
                        Text(
                          '... and ${(route['waypoints'] as List).length - 3} more steps',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Action buttons
                _buildRouteActions(route),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteActions(Map<String, dynamic> route) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyRoute = currentUser?.uid == route['helperUserId'];

    return Row(
      children: [
        // Accept button (only for help request owner)
        if (widget.isOwner && !isMyRoute)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptRoute(route['id'], route['helperUserId'] ?? ''),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

        // Delete button (only for route creator)
        if (isMyRoute) ...[
          if (widget.isOwner) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _deleteRoute(route['id'], route['helperUserId'] ?? ''),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],

        // View Details button
        if (!widget.isOwner || isMyRoute)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRouteDetails(route),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Recently';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showRouteDetails(Map<String, dynamic> route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(route['routeName'] ?? route['title'] ?? 'Route Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Created by: ${route['helperUsername'] ?? 'Anonymous'}'),
            const SizedBox(height: 8),
            if (route['description'] != null && route['description'].toString().isNotEmpty) ...[
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(route['description']),
              const SizedBox(height: 12),
            ],
            if (route['waypoints'] != null && (route['waypoints'] as List).isNotEmpty) ...[
              const Text('All Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(route['waypoints'] as List).asMap().entries.map<Widget>((entry) {
                final index = entry.key;
                final waypoint = entry.value;
                final instruction = waypoint['instruction'] ?? waypoint.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${index + 1}. $instruction'),
                );
              }).toList(),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
