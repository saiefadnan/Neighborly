import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/components/help_request_drawer.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key, this.autoOpenHelpDrawer = false});

  final bool autoOpenHelpDrawer;

  @override
  _MapHomePageState createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;

  final List<Map<String, dynamic>> helpRequests = [
    {
      "type": "Emergency",
      "location": LatLng(23.8103, 90.4125),
      "description": "Medical emergency near Dhanmondi",
      "title": "Medical Emergency",
      "time": "5 mins ago",
      "priority": "high",
    },
    {
      "type": "Urgent",
      "location": LatLng(23.8115, 90.4090),
      "description": "Need groceries for elder person",
      "title": "Grocery Help Needed",
      "time": "15 mins ago",
      "priority": "medium",
    },
    {
      "type": "General",
      "location": LatLng(23.8127, 90.4150),
      "description": "Looking for direction to new clinic",
      "title": "Direction Help",
      "time": "1 hour ago",
      "priority": "low",
    },
  ];

  @override
  void initState() {
    super.initState();
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
    _createMarkers();

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
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _createMarkers() async {
    Set<Marker> markers = {};

    for (int idx = 0; idx < helpRequests.length; idx++) {
      Map<String, dynamic> req = helpRequests[idx];

      BitmapDescriptor customIcon = await _createCustomMarker(req['type']);

      markers.add(
        Marker(
          markerId: MarkerId('help_request_$idx'),
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

    setState(() {
      _markers = markers;
    });
  }

  Future<BitmapDescriptor> _createCustomMarker(String type) async {
    double hue;
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

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  void _showHelpRequestBottomSheet(Map<String, dynamic> helpData) {
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

                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/dummy.png', // Default user image
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
                          Text(
                            'Anonymous User', // Default name
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dhanmondi Area', // Default location
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
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

                // Details
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
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
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
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dhanmondi Area (0.5 km away)',
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
                            '+880 1XXX-XXXXXX',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              // Call functionality
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
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        '${(helpData['responders'] ?? 2)} people are responding to this request',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Add respond functionality here
                    },
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
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case "Emergency":
        return Colors.red;
      case "Urgent":
        return Colors.orange;
      default:
        return Color(0xFF71BB7B);
    }
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

  void _openHelpRequestDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => HelpRequestDrawer(
            onSubmit: (helpData) {
              setState(() {
                helpRequests.add(helpData);
                _createMarkers();
              });
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
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
                  target: LatLng(23.8103, 90.4125),
                  zoom: 14.0,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔮 Chatbot Icon (NEW)
          SizedBox(height: 10),

          // 🗣 Community Forum (Unchanged)
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
            child: Icon(Icons.forum),
          ),
          SizedBox(height: 10),

          // ➕ Add Help Request (Updated to use new method)
          FloatingActionButton(
            heroTag: "addHelp",
            onPressed: _openHelpRequestDrawer,
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
            tooltip: "Add Help Request",
            child: Icon(Icons.add),
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
}