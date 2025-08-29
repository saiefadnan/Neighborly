import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/components/help_request_drawer.dart';
import 'package:neighborly/components/route_sharing_bottom_sheet.dart';
import 'package:neighborly/services/map_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({
    super.key,
    this.autoOpenHelpDrawer = false,
    this.targetLocation,
    this.targetLocationName,
  });

  final bool autoOpenHelpDrawer;
  final LatLng? targetLocation;
  final String? targetLocationName;

  @override
  _MapHomePageState createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;

  // Current user from Firebase Auth
  String? currentUserId;
  List<Map<String, dynamic>> helpRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Get current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    currentUserId = user?.uid;

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _headerAnimationController.forward();

    // Load help requests from API
    _loadHelpRequests();

    // Auto-open help drawer if requested
    if (widget.autoOpenHelpDrawer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a small delay to ensure the page is fully loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _openHelpRequestDrawer();
          }
        });
      });
    }

    // Handle target location navigation or auto-navigate to current location
    if (widget.targetLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _mapController != null) {
            _navigateToTargetLocation();
          }
        });
      });
    } else {
      // Auto-navigate to current location when map loads
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && _mapController != null) {
            _navigateToCurrentLocation();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  // Load help requests from API
  Future<void> _loadHelpRequests() async {
    if (currentUserId == null) {
      //print('User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user's current location for nearby requests
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // If location permission denied, get all requests
        final result = await MapService.getHelpRequests(limit: 100);
        //print('API Result: ${result.toString()}');
        if (result['success']) {
          //print('Raw data from API: ${result['data']}');
          setState(() {
            helpRequests =
                (result['data'] as List).map((item) {
                  //print('Converting item: $item');
                  return MapService.convertApiResponseToUIFormat(item);
                }).toList();
            _isLoading = false;
          });
          //print('Converted help requests: ${helpRequests.length} items');
          _createMarkers();
        } else {
          throw Exception(result['message']);
        }
      } else {
        // Get nearby requests based on location
        Position position = await Geolocator.getCurrentPosition();

        // Check if we're getting emulator coordinates (California)
        bool isEmulatorLocation =
            (position.latitude >= 37.0 &&
                position.latitude <= 38.0 &&
                position.longitude >= -123.0 &&
                position.longitude <= -121.0);

        double searchLat, searchLng;
        if (isEmulatorLocation) {
          // Use MIST, Mirpur Cantonment coordinates for development
          searchLat = 23.8223;
          searchLng = 90.3654;
          //print('Using MIST coordinates for emulator: $searchLat, $searchLng');
        } else {
          searchLat = position.latitude;
          searchLng = position.longitude;
          //print('Using real GPS coordinates: $searchLat, $searchLng');
        }

        final result = await MapService.getNearbyHelpRequests(
          latitude: searchLat,
          longitude: searchLng,
          radiusKm: 20.0, // 20km radius
        );

        if (result['success'] && (result['data'] as List).isNotEmpty) {
          print('Raw nearby data from API: ${result['data']}');
          setState(() {
            helpRequests =
                (result['data'] as List).map((item) {
                  print('Converting nearby item: $item');
                  return MapService.convertApiResponseToUIFormat(item);
                }).toList();
            _isLoading = false;
          });
          print('Converted nearby help requests: ${helpRequests.length} items');
          _createMarkers();
        } else {
          // If no nearby requests found, get all requests as fallback
          print('No nearby requests found, getting all requests...');
          final fallbackResult = await MapService.getHelpRequests(limit: 100);
          if (fallbackResult['success']) {
            print('Fallback data from API: ${fallbackResult['data']}');
            setState(() {
              helpRequests =
                  (fallbackResult['data'] as List).map((item) {
                    print('Converting fallback item: $item');
                    return MapService.convertApiResponseToUIFormat(item);
                  }).toList();
              _isLoading = false;
            });
            print(
              'Converted fallback help requests: ${helpRequests.length} items',
            );
            _createMarkers();
          } else {
            throw Exception(fallbackResult['message']);
          }
        }
      }
    } catch (e) {
      print('Error loading help requests: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load help requests: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMarkers() async {
    print('Creating markers for ${helpRequests.length} help requests');
    Set<Marker> markers = {};

    // Add regular help request markers
    for (int idx = 0; idx < helpRequests.length; idx++) {
      Map<String, dynamic> req = helpRequests[idx];
      print(
        'Creating marker for request $idx: ${req['id']} at ${req['location']}',
      );

      BitmapDescriptor customIcon = await _createCustomMarker(req);

      markers.add(
        Marker(
          markerId: MarkerId('help_request_${req['id']}'),
          position: req['location'],
          infoWindow: InfoWindow(
            title: req['title'] ?? req['type'],
            snippet: req['description'],
          ),
          icon: customIcon,
          onTap: () {
            _showHelpRequestBottomSheet(req);
          },
        ),
      );
    }

    // Add target location marker if provided
    if (widget.targetLocation != null) {
      BitmapDescriptor targetIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/dummy.png', // You can replace this with a special icon
      ).catchError(
        (_) => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('target_location'),
          position: widget.targetLocation!,
          infoWindow: InfoWindow(
            title: widget.targetLocationName ?? 'Selected Location',
            snippet: 'Notification target location',
          ),
          icon: targetIcon,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'You are viewing ${widget.targetLocationName ?? "the selected location"}',
                ),
                backgroundColor: const Color(0xFF71BB7B),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }

    print('Created ${markers.length} markers total');
    setState(() {
      _markers = markers;
    });
  }

  Future<void> _navigateToTargetLocation() async {
    if (widget.targetLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.targetLocation!,
            zoom: 16.0, // Zoom closer to show the specific location
          ),
        ),
      );

      // Show a snackbar to indicate navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Showing location: ${widget.targetLocationName ?? "Selected location"}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF71BB7B),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Navigate to current location (or MIST for emulator)
  Future<void> _navigateToCurrentLocation() async {
    if (_mapController == null) return;

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      LatLng targetLocation;
      String locationName;

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Use MIST coordinates as default
        targetLocation = const LatLng(23.8223, 90.3654);
        locationName = 'MIST, Mirpur Cantonment';
        print('Location permission denied, using MIST coordinates');
      } else {
        // Get current position
        Position position = await Geolocator.getCurrentPosition();

        // Check if we're getting emulator coordinates (California)
        bool isEmulatorLocation =
            (position.latitude >= 37.0 &&
                position.latitude <= 38.0 &&
                position.longitude >= -123.0 &&
                position.longitude <= -121.0);

        if (isEmulatorLocation) {
          // Use MIST coordinates for emulator
          targetLocation = const LatLng(23.8223, 90.3654);
          locationName = 'MIST, Mirpur Cantonment (Emulator)';
          print('Emulator detected, using MIST coordinates');
        } else {
          // Use real GPS coordinates
          targetLocation = LatLng(position.latitude, position.longitude);
          locationName = 'Your Current Location';
          print(
            'Using real GPS coordinates: ${position.latitude}, ${position.longitude}',
          );
        }
      }

      // Animate to the target location
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 17.0, // Good zoom level for neighborhood view
          ),
        ),
      );

      // Show location indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.my_location, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Navigated to: $locationName',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF71BB7B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to current location: $e');
      // Fallback to MIST coordinates
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: const LatLng(23.8223, 90.3654), zoom: 17.0),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Navigated to: MIST, Mirpur Cantonment',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF71BB7B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Create dummy help requests for testing
  Future<void> _createDummyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await MapService.createDummyHelpRequests();

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.add_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Created ${result['count']} dummy help requests',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Reload help requests to show the new dummy data
        await _loadHelpRequests();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      print('Error creating dummy data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to create dummy data',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Remove all dummy help requests
  Future<void> _removeDummyData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await MapService.removeDummyHelpRequests();

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.delete_sweep, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Removed ${result['removedCount']} dummy help requests',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Reload help requests to reflect the removal
        await _loadHelpRequests();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      print('Error removing dummy data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to remove dummy data',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(
    Map<String, dynamic> request,
  ) async {
    String type = request['type'];
    String status = request['status'] ?? 'open';
    bool isMyRequest = request['userId'] == currentUserId;

    double hue;

    // If it's in progress (accepted responder), use different color
    if (status == 'in_progress') {
      hue = BitmapDescriptor.hueBlue; // Blue for in-progress
    } else if (isMyRequest) {
      hue = BitmapDescriptor.hueViolet; // Purple for my requests
    } else {
      // Original logic for other requests
      switch (type) {
        case "Emergency":
          hue = BitmapDescriptor.hueRed;
          break;
        case "Urgent":
          hue = BitmapDescriptor.hueOrange;
          break;
        default:
          hue = BitmapDescriptor.hueGreen;
          break;
      }
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  void _showHelpRequestBottomSheet(Map<String, dynamic> helpData) {
    bool isMyRequest = helpData['userId'] == currentUserId;
    String status = helpData['status'] ?? 'open';
    List<dynamic> responders = helpData['responders'] ?? [];
    String? acceptedResponderId = helpData['acceptedResponderId'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header with status indicator
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/dummy.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                helpData['username'] ?? 'Anonymous User',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isMyRequest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            helpData['address'] ?? 'Dhanmondi Area',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getUrgencyColor(helpData['type']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            helpData['type'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Help Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHelpTypeIcon(helpData['type']),
                        size: 18,
                        color: const Color(0xFF71BB7B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        helpData['type'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71BB7B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  helpData['title'] ?? helpData['type'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  helpData['description'],
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Show different content based on ownership and status
                if (isMyRequest) ...[
                  _buildMyRequestContent(
                    helpData,
                    responders,
                    acceptedResponderId,
                    status,
                  ),
                ] else ...[
                  _buildOtherRequestContent(
                    helpData,
                    status,
                    acceptedResponderId,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Emergency':
        return Colors.red;
      case 'Urgent':
        return Colors.orange;
      case 'General':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Content for requests owned by current user
  Widget _buildMyRequestContent(
    Map<String, dynamic> helpData,
    List<dynamic> responders,
    String? acceptedResponderId,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Posted: ${helpData['time'] ?? 'Just now'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      helpData['address'] ?? 'Address not specified',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Responders section
        if (status == 'in_progress' && acceptedResponderId != null) ...[
          _buildAcceptedResponderSection(
            helpData,
            responders,
            acceptedResponderId,
          ),
        ] else if (responders.isNotEmpty) ...[
          _buildRespondersSection(helpData, responders),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_empty, color: Colors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No responses yet. Your request is visible to nearby helpers.',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Action buttons for my requests
        if (status == 'in_progress') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markRequestCompleted(helpData),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _cancelAcceptedResponder(helpData),
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel Current Responder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else if (status == 'open') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _deleteRequest(helpData),
              icon: const Icon(Icons.delete),
              label: const Text('Delete Request'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Content for requests from other users
  Widget _buildOtherRequestContent(
    Map<String, dynamic> helpData,
    String status,
    String? acceptedResponderId,
  ) {
    bool canRespond = status == 'open';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    'Posted: ${helpData['time'] ?? 'Just now'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${helpData['address']} (0.5 km away)',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.phone, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    helpData['phone'] ?? '+880 1XXX-XXXXXX',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      final phoneNumber = helpData['phone'] ?? '';
                      if (phoneNumber.isNotEmpty) {
                        _makePhoneCall(phoneNumber);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No phone number available'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF71BB7B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.call,
                        size: 16,
                        color: Color(0xFF71BB7B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Response status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                canRespond
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                canRespond ? Icons.people : Icons.schedule,
                color: canRespond ? Colors.blue : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  canRespond
                      ? '${(helpData['responders'] as List).length} people are responding to this request'
                      : status == 'in_progress'
                      ? 'This request is currently being handled'
                      : 'This request is no longer accepting responses',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: canRespond ? Colors.blue : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action button
        SizedBox(
          width: double.infinity,
          child:
              canRespond
                  ? (helpData['title'] == 'Route' || helpData['type'] == 'Route'
                      ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showRouteHelper(helpData);
                        },
                        icon: const Icon(Icons.route),
                        label: const Text('Help with Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                      : ElevatedButton.icon(
                        onPressed: () => _respondToRequest(helpData),
                        icon: const Icon(Icons.reply),
                        label: const Text('Respond to Help Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF71BB7B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ))
                  : Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        status == 'in_progress'
                            ? 'Request is being handled'
                            : 'Request is closed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
        ),
      ],
    );
  }

  // Build responders list for my requests (when no one is accepted yet)
  Widget _buildRespondersSection(
    Map<String, dynamic> helpData,
    List<dynamic> responders,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People Offering Help (${responders.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ...responders.map(
          (responder) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: const AssetImage('assets/images/dummy.png'),
                  radius: 25,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        responder['username'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Responded ${responder['responseTime'] ?? 'recently'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        responder['phone'] ?? 'No phone provided',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _acceptResponder(helpData, responder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getHelpTypeIcon(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Icons.local_hospital;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Grocery':
        return Icons.shopping_cart;
      case 'Shifting House':
        return Icons.home;
      case 'Shifting Furniture':
        return Icons.chair;
      case 'Traffic Update':
        return Icons.traffic;
      case 'Route':
        return Icons.directions;
      case 'Lost Person':
        return Icons.person_search;
      case 'Lost Item/Pet':
        return Icons.pets;
      case 'Emergency':
        return Icons.emergency;
      case 'Urgent':
        return Icons.priority_high;
      case 'General':
        return Icons.help;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean and format the phone number
    String cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Ensure the number starts with + for international format
    if (!cleanedNumber.startsWith('+')) {
      // If it's a Bangladesh number starting with 01, add country code
      if (cleanedNumber.startsWith('01')) {
        cleanedNumber = '+880${cleanedNumber.substring(1)}';
      } else if (!cleanedNumber.startsWith('880') &&
          cleanedNumber.length >= 10) {
        // Add + if it doesn't have it
        cleanedNumber = '+$cleanedNumber';
      }
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanedNumber);
    print('Attempting to call: $cleanedNumber');
    print('URI: $phoneUri');

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication, // Force external app
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No phone app found to make call to $cleanedNumber',
              ),
              action: SnackBarAction(
                label: 'Copy Number',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cleanedNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Phone number copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Phone call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to make phone call. Please dial manually: $cleanedNumber',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openHelpRequestDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => HelpRequestDrawer(
            onSubmit: (helpData) async {
              if (currentUserId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to create help requests'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Creating help request...'),
                    ],
                  ),
                  backgroundColor: Color(0xFF71BB7B),
                  duration: Duration(seconds: 30),
                ),
              );

              try {
                final result = await MapService.createHelpRequest(
                  type: helpData['type'] ?? 'General',
                  title:
                      helpData['title'] ?? helpData['type'] ?? 'Help Request',
                  description: helpData['description'] ?? '',
                  location:
                      helpData['location'] ??
                      const LatLng(23.8223, 90.3654), // MIST coordinates
                  address: helpData['address'] ?? '',
                  priority: helpData['priority'] ?? 'medium',
                  phone: helpData['phone'],
                );

                // Hide loading indicator
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if (result['success']) {
                  // Add the new request to local state
                  final newRequest = MapService.convertApiResponseToUIFormat(
                    result['data'],
                  );
                  setState(() {
                    helpRequests.add(newRequest);
                    _createMarkers();
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Your help request has been posted! Nearby helpers will be notified.',
                      ),
                      backgroundColor: const Color(0xFF71BB7B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['message'] ?? 'Failed to create help request',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } catch (e) {
                // Hide loading indicator
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error creating help request: ${e.toString()}',
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
    );
  }

  // Build accepted responder section (when someone is already helping)
  Widget _buildAcceptedResponderSection(
    Map<String, dynamic> helpData,
    List<dynamic> responders,
    String acceptedResponderId,
  ) {
    final acceptedResponder = responders
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (r) => r['userId'] == acceptedResponderId,
          orElse: () => <String, dynamic>{},
        );

    if (acceptedResponder.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Currently Being Helped By:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: const AssetImage('assets/images/dummy.png'),
                radius: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          acceptedResponder['username'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Helping',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Accepted ${acceptedResponder['responseTime'] ?? 'recently'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      acceptedResponder['phone'] ?? 'No phone provided',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  final phoneNumber = acceptedResponder['phone'] ?? '';
                  if (phoneNumber.isNotEmpty) {
                    _makePhoneCall(phoneNumber);
                  }
                },
                icon: const Icon(Icons.call, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Accept a responder for my request
  void _acceptResponder(
    Map<String, dynamic> helpData,
    Map<String, dynamic> responder,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Accept Helper'),
          content: Text(
            'Do you want to accept ${responder['username']} as your helper? They will be notified and you can coordinate directly.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the bottom sheet too

                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to accept helpers'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Accepting helper...'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 30),
                  ),
                );

                try {
                  final result = await MapService.acceptResponder(
                    requestId: helpData['id'],
                    responseId:
                        responder['userId'], // Using userId as responseId for compatibility
                  );

                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (result['success']) {
                    // Refresh the help requests to get updated data
                    await _loadHelpRequests();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${responder['username']} has been accepted as your helper!',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to accept helper',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accepting helper: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF71BB7B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  // Respond to someone else's request
  void _respondToRequest(Map<String, dynamic> helpData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Offer Help'),
          content: Text(
            'Do you want to offer help for "${helpData['title']}"? The requester will see your response and can choose to accept your help.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the bottom sheet too

                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to respond to requests'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Sending response...'),
                      ],
                    ),
                    backgroundColor: Color(0xFF71BB7B),
                    duration: Duration(seconds: 30),
                  ),
                );

                try {
                  final user = FirebaseAuth.instance.currentUser;
                  final result = await MapService.respondToHelpRequest(
                    requestId: helpData['id'],
                    message: 'I can help with this request',
                    phone: user?.phoneNumber ?? '',
                    username: user?.displayName ?? 'Anonymous Helper',
                  );

                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (result['success']) {
                    // Refresh the help requests to get updated data
                    await _loadHelpRequests();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Your response has been sent! The requester will be notified.',
                        ),
                        backgroundColor: const Color(0xFF71BB7B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to send response',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error sending response: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF71BB7B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Response'),
            ),
          ],
        );
      },
    );
  }

  // Mark request as completed
  void _markRequestCompleted(Map<String, dynamic> helpData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Mark as Completed'),
          content: const Text(
            'Are you sure your request has been fulfilled? This will remove it from the map and notify your helper.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the bottom sheet too

                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to complete requests'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Completing request...'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 30),
                  ),
                );

                try {
                  final result = await MapService.updateHelpRequestStatus(
                    requestId: helpData['id'],
                    status: 'completed',
                  );

                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (result['success']) {
                    // Remove the request from local state
                    setState(() {
                      helpRequests.removeWhere(
                        (r) => r['id'] == helpData['id'],
                      );
                      _createMarkers(); // Refresh markers
                    });

                    // Add this log to confirm helpedRequests creation is triggered
                    print(
                      '✅ Request ${helpData['id']} completed - helpedRequests entry should be created if responder was accepted',
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Request marked as completed! Thank you for using Neighborly.',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to complete request',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error completing request: ${e.toString()}',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  // Cancel accepted responder
  void _cancelAcceptedResponder(Map<String, dynamic> helpData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Cancel Current Helper'),
          content: const Text(
            'Are you sure you want to cancel your current helper? This will make your request open for responses again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the bottom sheet too

                setState(() {
                  // Update the request to mark it as open again
                  final requestIndex = helpRequests.indexWhere(
                    (r) => r['id'] == helpData['id'],
                  );
                  if (requestIndex != -1) {
                    helpRequests[requestIndex]['status'] = 'open';
                    helpRequests[requestIndex]['acceptedResponderId'] = null;
                  }
                  _createMarkers(); // Refresh markers
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Helper cancelled. Your request is now open for responses again.',
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Helper'),
            ),
          ],
        );
      },
    );
  }

  // Delete request
  void _deleteRequest(Map<String, dynamic> helpData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Delete Request'),
          content: const Text(
            'Are you sure you want to delete your help request? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the bottom sheet too

                if (currentUserId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to delete requests'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Deleting request...'),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 30),
                  ),
                );

                try {
                  final result = await MapService.deleteHelpRequest(
                    requestId: helpData['id'],
                  );

                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (result['success']) {
                    // Remove the request from local state
                    setState(() {
                      helpRequests.removeWhere(
                        (r) => r['id'] == helpData['id'],
                      );
                      _createMarkers(); // Refresh markers
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Request deleted successfully.'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to delete request',
                        ),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Hide loading
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting request: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          kIsWeb
              ? Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF7F2E7), Color(0xFFE8F4EA)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 80,
                              color: Color(0xFF71BB7B),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Map Feature',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E5E3E),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Map functionality is currently available\non mobile devices only.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF71BB7B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                'Try on mobile for full experience',
                                style: TextStyle(
                                  color: Color(0xFF71BB7B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      widget.targetLocation ??
                      const LatLng(
                        23.8223,
                        90.3654,
                      ), // MIST coordinates as default
                  zoom: widget.targetLocation != null ? 16.0 : 15.0,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // If we have a target location, navigate to it after map is created
                  if (widget.targetLocation != null) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        _navigateToTargetLocation();
                      }
                    });
                  }
                },
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
                buildingsEnabled: true,
                indoorViewEnabled: true,
                trafficEnabled: false,
              ),

          // Loading overlay
          if (_isLoading && !kIsWeb)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF71BB7B),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading help requests...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // � My Location Button (NEW)
          FloatingActionButton(
            heroTag: "myLocation",
            onPressed: _navigateToCurrentLocation,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            tooltip: "Go to My Location",
            mini: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),

          // 🗣 Community Forum
          FloatingActionButton(
            heroTag: "chat",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumPage(title: 'NeighborTalk'),
                ),
              );
            },
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
            tooltip: "Community Forum",
            child: const Icon(Icons.forum),
          ),
          const SizedBox(height: 10),

          // ➕ Add Help Request
          FloatingActionButton(
            heroTag: "addHelp",
            onPressed: _openHelpRequestDrawer,
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
            tooltip: "Add Help Request",
            child: const Icon(Icons.add),
          ),
        ],
      ),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        179,
                        0,
                        0,
                        0,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.map,
                      color: Color.fromARGB(179, 0, 0, 0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Neighborly Map",
                    style: TextStyle(
                      color: Color.fromARGB(179, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFFFAF4E8),
        foregroundColor: const Color.fromARGB(179, 0, 0, 0),
      ),
    );
  }

  Future<void> _showRouteHelper(Map<String, dynamic> helpData) async {
    try {
      // Get current user location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission is required to help with routing',
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is permanently denied. Please enable it in settings.',
              ),
            ),
          );
        }
        return;
      }

      Position userPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      final userLocation = LatLng(
        userPosition.latitude,
        userPosition.longitude,
      );

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false, // Prevent dismissal by tapping outside
          enableDrag: false, // Prevent drag to dismiss
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder:
              (context) => RouteSharingBottomSheet(
                helpData: helpData,
                userLocation: userLocation,
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }
}
