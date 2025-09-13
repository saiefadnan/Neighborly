import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/components/help_request_drawer.dart';
import 'package:neighborly/components/responses_drawer.dart';
import 'package:neighborly/components/route_sharing_bottom_sheet.dart';
import 'package:neighborly/components/shared_routes_bottom_sheet.dart';
import 'package:neighborly/services/map_service.dart';
import 'package:neighborly/providers/help_request_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    _mapController?.dispose();
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
      if (!mounted) return;
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
      print(
        "Request type: ${req['type']}, status: ${req['status']}, title: ${req['title']}, userId: ${req['userId']}",
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
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _navigateToTargetLocation() async {
    if (widget.targetLocation != null && _mapController != null && mounted) {
      try {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: widget.targetLocation!,
              zoom: 16.0, // Zoom closer to show the specific location
            ),
          ),
        );
      } catch (e) {
        print('Error animating camera in _navigateToTargetLocation: $e');
        return;
      }

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
      if (mounted && _mapController != null) {
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: targetLocation,
                zoom: 17.0, // Good zoom level for neighborhood view
              ),
            ),
          );
        } catch (e) {
          print('Error animating camera in _navigateToCurrentLocation: $e');
          return;
        }
      }

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
      if (mounted && _mapController != null) {
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: const LatLng(23.8223, 90.3654),
                zoom: 17.0,
              ),
            ),
          );
        } catch (fallbackError) {
          print('Error in fallback camera animation: $fallbackError');
          return;
        }
      }

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

  Future<BitmapDescriptor> _createCustomMarker(
    Map<String, dynamic> request,
  ) async {
    String type = request['title'];
    String status = request['status'] ?? 'open';
    String urgency = request['urgency'] ?? request['priority'] ?? 'general';
    bool isMyRequest = request['userId'] == currentUserId;

    // Determine background color based on urgency
    Color backgroundColor;
    if (isMyRequest) {
      backgroundColor = Colors.purple; // Purple for my requests
    } else if (status == 'in_progress') {
      backgroundColor = Colors.blue; // Blue for in-progress
    } else {
      // Use urgency-based colors
      switch (urgency.toLowerCase()) {
        case 'emergency':
        case 'high':
          backgroundColor = Colors.red;
          break;
        case 'urgent':
        case 'medium':
          backgroundColor = Colors.orange;
          break;
        case 'general':
        case 'low':
        default:
          backgroundColor = Colors.green;
          break;
      }
    }

    // Get icon based on help type
    IconData iconData = _getHelpTypeIcon(type);

    // Create custom marker
    return await _createCustomMarkerFromIcon(
      iconData: iconData,
      backgroundColor: backgroundColor,
      size: 120.0, // Increased from 80.0 to 120.0 for larger markers
    );
  }

  // Helper method to get help type icons (exactly matching help_request_drawer.dart)
  IconData _getHelpTypeIcon(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Icons.medical_services;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Shifting House':
        return Icons.house;
      case 'Grocery':
        return Icons.shopping_cart;
      case 'Traffic Update':
        return Icons.traffic;
      case 'Route':
        return Icons.directions;
      case 'Shifting Furniture':
        return Icons.chair;
      case 'Lost Person':
        return Icons.person_search;
      case 'Lost Item/Pet':
        return Icons.pets;
      default:
        return Icons.help_outline;
    }
  }

  // Create custom marker with icon and background color
  Future<BitmapDescriptor> _createCustomMarkerFromIcon({
    required IconData iconData,
    required Color backgroundColor,
    required double size,
  }) async {
    final recorder = ui.PictureRecorder();

    // Calculate canvas size to accommodate the more reasonable aura
    final canvasSize = size * 2.0; // Reduced canvas size
    final center = canvasSize / 2; // Perfect center point

    final canvas = Canvas(recorder);

    // Create enhanced pulsing aura effect with more reasonable size
    final maxAuraRadius = size * 0.6; // Reduced aura radius (was 1.0, now 0.6)

    // Draw multiple aura rings with varying opacity to simulate pulsing
    for (int i = 6; i >= 1; i--) {
      final ringRadius =
          maxAuraRadius * (0.3 + (i * 0.12)); // More gradual ring progression
      final baseOpacity =
          0.15 - (i * 0.02); // Decreasing opacity for outer rings

      // Create pulsing effect by varying opacity in a wave pattern
      final pulseOpacity =
          baseOpacity +
          (0.05 * (i % 2 == 0 ? 1 : 0.5)); // Alternating intensity

      final auraPaint =
          Paint()
            ..color = backgroundColor.withOpacity(pulseOpacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(center, center), ringRadius, auraPaint);
    }

    // Add inner glow rings for more depth
    for (int i = 3; i >= 1; i--) {
      final innerRadius = size * 0.2 * (1 + i * 0.3);
      final glowOpacity = 0.3 - (i * 0.08);

      final glowPaint =
          Paint()
            ..color = backgroundColor.withOpacity(glowOpacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(center, center), innerRadius, glowPaint);
    }

    // Draw main circular background - larger size
    final mainRadius = size * 0.4; // Increased main marker radius
    final paint = Paint()..color = backgroundColor;
    canvas.drawCircle(Offset(center, center), mainRadius, paint);

    // Draw white border for the main marker
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..strokeWidth =
              3.5 // Thicker border for larger marker
          ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(center, center), mainRadius - 1.75, borderPaint);

    // Draw icon - larger size
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.35, // Increased from 0.3 to 0.35 (bigger icons)
        fontFamily: iconData.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    // Center the icon perfectly
    final iconOffset = Offset(
      center - (textPainter.width / 2),
      center - (textPainter.height / 2),
    );
    textPainter.paint(canvas, iconOffset);

    // Convert to image with proper dimensions
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.toInt(), canvasSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
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
                        _getHelpTypeIcon(helpData['title']),
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
    switch (urgency.toLowerCase()) {
      case 'emergency':
      case 'high':
        return Colors.red;
      case 'urgent':
      case 'medium':
        return Colors.orange;
      case 'general':
      case 'low':
      default:
        return Colors.green;
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
          // Use ResponsesDrawer for responder management
          InkWell(
            onTap: () {
              Navigator.of(context).pop(); // Close current bottom sheet
              final helpRequestData = _convertToHelpRequestData(helpData);
              ResponsesDrawer.show(context, helpRequestData);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${responders.length} people are responding to this request',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
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
          // Show Routes button for route-type requests
          if (helpData['type'] == 'Route' || helpData['title'] == 'Route') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRoutesForMyRequest(helpData),
                icon: const Icon(Icons.route),
                label: const Text('Show Routes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
        InkWell(
          onTap: () {
            if (canRespond && (helpData['responders'] as List).isNotEmpty) {
              // Convert helpData to HelpRequestData format for ResponsesDrawer
              final helpRequestData = HelpRequestData(
                id: helpData['id'] ?? '',
                title: helpData['title'] ?? helpData['type'] ?? '',
                description: helpData['description'] ?? '',
                helpType: helpData['type'] ?? '',
                urgency:
                    helpData['urgency'] ?? helpData['priority'] ?? 'general',
                location: helpData['address'] ?? '',
                distance: '0.5 km',
                timePosted: helpData['time'] ?? 'Just now',
                requesterName: helpData['requesterName'] ?? 'Anonymous',
                requesterImage: 'assets/images/dummy.png',
                contactNumber: helpData['phone'] ?? '',
                status: helpData['status'] ?? 'open',
                responderCount: (helpData['responders'] as List).length,
                isResponded: false,
                userId: helpData['userId'] ?? '',
              );

              Navigator.of(context).pop(); // Close current bottom sheet
              ResponsesDrawer.show(context, helpRequestData);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  canRespond
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  canRespond && (helpData['responders'] as List).isNotEmpty
                      ? Border.all(color: Colors.blue.withOpacity(0.3))
                      : null,
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
                if (canRespond &&
                    (helpData['responders'] as List).isNotEmpty) ...[
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action button
        SizedBox(
          width: double.infinity,
          child: _buildResponseButton(helpData, canRespond),
        ),
      ],
    );
  }

  // Convert Map to HelpRequestData for ResponsesDrawer
  HelpRequestData _convertToHelpRequestData(Map<String, dynamic> helpData) {
    return HelpRequestData(
      id: helpData['id'] ?? '',
      title: helpData['title'] ?? helpData['type'] ?? '',
      description: helpData['description'] ?? '',
      helpType: helpData['type'] ?? '',
      urgency: helpData['urgency'] ?? helpData['priority'] ?? 'general',
      location: helpData['address'] ?? '',
      distance: '0.5 km',
      timePosted: helpData['time'] ?? 'Just now',
      requesterName: helpData['requesterName'] ?? 'Anonymous',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: helpData['phone'] ?? '',
      status: helpData['status'] ?? 'open',
      responderCount: (helpData['responders'] as List?)?.length ?? 0,
      isResponded: false,
      userId: helpData['userId'] ?? '',
    );
  }

  // Check if current user has already responded to a help request
  Future<Map<String, dynamic>?> _checkUserResponse(String requestId) async {
    if (currentUserId == null) return null;

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('helpRequests')
              .doc(requestId)
              .collection('responses')
              .where('userId', isEqualTo: currentUserId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {
          'id': querySnapshot.docs.first.id,
          ...querySnapshot.docs.first.data(),
        };
      }
      return null;
    } catch (e) {
      print('Error checking user response: $e');
      return null;
    }
  }

  // Build response button with status checking
  Widget _buildResponseButton(Map<String, dynamic> helpData, bool canRespond) {
    if (!canRespond) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            helpData['status'] == 'in_progress'
                ? 'Request is being handled'
                : 'Request is closed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _checkUserResponse(helpData['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ElevatedButton.icon(
            onPressed: null,
            icon: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: const Text('Checking...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        final existingResponse = snapshot.data;
        if (existingResponse != null) {
          String status = existingResponse['status'] ?? 'pending';
          switch (status) {
            case 'accepted':
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'Response Accepted',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            case 'rejected':
              return ElevatedButton.icon(
                onPressed: () => _respondToRequest(helpData),
                icon: const Icon(Icons.refresh),
                label: const Text('Respond Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            case 'pending':
            default:
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Response Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
          }
        }

        // No existing response - show normal respond button
        if (helpData['title'] == 'Route' || helpData['type'] == 'Route') {
          return ElevatedButton.icon(
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
          );
        } else {
          return ElevatedButton.icon(
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
          );
        }
      },
    );
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
                  duration: Duration(seconds: 3),
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
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Your help request has been posted successfully! Nearby helpers will be notified.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              result['message'] ??
                                  'Failed to create help request',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                // Hide loading indicator
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Error creating help request: ${e.toString()}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 4),
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

  // Respond to someone else's request (Enhanced version like help_list.dart)
  void _respondToRequest(Map<String, dynamic> helpData) async {
    // Check if user has already responded
    final existingResponse = await _checkUserResponse(helpData['id']);

    if (existingResponse != null) {
      String status = existingResponse['status'] ?? 'pending';
      String message;
      Color backgroundColor;
      IconData icon;

      switch (status) {
        case 'accepted':
          message =
              'Your response was accepted! You are helping with this request.';
          backgroundColor = Colors.green;
          icon = Icons.check_circle;
          break;
        case 'rejected':
          message =
              'Your previous response was declined. You can respond again if you wish.';
          backgroundColor = Colors.orange;
          icon = Icons.info;
          break;
        case 'pending':
        default:
          message =
              'You have already responded to this request. Please wait for the requester to review your response.';
          backgroundColor = Colors.blue;
          icon = Icons.pending;
          break;
      }

      Navigator.of(context).pop(); // Close current bottom sheet

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action:
              status == 'rejected'
                  ? SnackBarAction(
                    label: 'Respond Again',
                    textColor: Colors.white,
                    onPressed: () => _showResponseModal(helpData),
                  )
                  : null,
        ),
      );

      if (status != 'rejected') return; // Don't show modal unless rejected
    }

    _showResponseModal(helpData);
  }

  void _showResponseModal(Map<String, dynamic> helpData) {
    Navigator.of(context).pop(); // Close current bottom sheet first

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final TextEditingController responseController =
            TextEditingController();
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      children: [
                        const SizedBox(height: 12),

                        // Header with icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF71BB7B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.volunteer_activism,
                                color: Color(0xFF71BB7B),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Respond to Help Request',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Helping ${helpData['requesterName'] ?? 'someone'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Help request summary card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF71BB7B).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF71BB7B).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getHelpTypeIcon(helpData['type'] ?? ''),
                                  color: const Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      helpData['title'] ??
                                          helpData['type'] ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      helpData['type'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getUrgencyColor(
                                    helpData['urgency'] ??
                                        helpData['priority'] ??
                                        'general',
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  helpData['type'] ??
                                      helpData['priority'] ??
                                      'General',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getUrgencyColor(
                                      helpData['urgency'] ??
                                          helpData['priority'] ??
                                          'general',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Response input section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.message_outlined,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Your Response',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const Text(
                                  ' *',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: responseController,
                                decoration: InputDecoration(
                                  hintText: 'Let them know how you can help...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 4,
                                textAlignVertical: TextAlignVertical.top,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF71BB7B),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFF71BB7B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (responseController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Please enter your response',
                                        ),
                                        backgroundColor: Colors.orange,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (currentUserId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please sign in to respond to requests',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.of(
                                    context,
                                  ).pop(); // Close the response modal

                                  // Show loading with shorter duration
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Text('Sending response...'),
                                        ],
                                      ),
                                      backgroundColor: Color(0xFF71BB7B),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );

                                  try {
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    final result =
                                        await MapService.respondToHelpRequest(
                                          requestId: helpData['id'],
                                          message:
                                              responseController.text.trim(),
                                          phone: user?.phoneNumber ?? '',
                                          username:
                                              user?.displayName ??
                                              'Anonymous Helper',
                                        );

                                    // Hide loading immediately
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();

                                    if (result['success']) {
                                      // Refresh the help requests to get updated data
                                      await _loadHelpRequests();

                                      // Show success message immediately
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Response sent successfully to ${helpData['requesterName'] ?? 'requester'}!',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: const Color(
                                            0xFF4CAF50,
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.error,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  result['message'] ??
                                                      'Failed to send response',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    // Hide loading immediately
                                    ScaffoldMessenger.of(
                                      context,
                                    ).hideCurrentSnackBar();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Error sending response: ${e.toString()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF71BB7B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Send Response',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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

  // Show routes for my request (for request owners)
  void _showRoutesForMyRequest(Map<String, dynamic> helpData) {
    Navigator.of(context).pop(); // Close current bottom sheet first

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SharedRoutesBottomSheet(
        helpRequestId: helpData['id'] ?? '',
        isOwner: true, // Current user is the request owner
        ownerUserId: currentUserId ?? '',
      ),
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
