import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/pages/notification.dart';
import 'package:neighborly/pages/profile.dart';
import 'package:neighborly/components/help_request_drawer.dart';
import 'package:neighborly/pages/placeHolder.dart';
import 'chat_screen.dart';

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  _MapHomePageState createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

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
    _createMarkers();
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
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(helpData['type']),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                helpData['type'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Spacer(),
                            Text(
                              helpData['time'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Text(
                          helpData['title'] ?? helpData['type'],
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          helpData['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Add chat functionality here
                                },
                                icon: Icon(Icons.message, color: Colors.white),
                                label: Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF71BB7B),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Add offer help functionality here
                                },
                                icon: Icon(
                                  Icons.volunteer_activism,
                                  color: Color(0xFF71BB7B),
                                ),
                                label: Text('Offer Help'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Color(0xFF71BB7B),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(color: Color(0xFF71BB7B)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
          FloatingActionButton(
            heroTag: "chatbot",
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            tooltip: "Ask NeighborBot",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen()),
              );
            },
            child: Icon(Icons.smart_toy_outlined),
          ),
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

          // ➕ Add Help Request (Unchanged)
          FloatingActionButton(
            heroTag: "addHelp",
            onPressed: () {
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
            },
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
            tooltip: "Add Help Request",
            child: Icon(Icons.add),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text(
          "Neighborly",
          style: TextStyle(
            color: Color.fromARGB(179, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFAF4E8),
        foregroundColor: const Color.fromARGB(179, 0, 0, 0),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
      ),
      drawer: _buildDrawer(context, ref),
    );
  }
}

Widget _buildDrawer(BuildContext context, WidgetRef ref) {
  String username = "Ali";
  void signOut() {
    ref.read(signedInProvider.notifier).state = false;
    context.go('/auth');
  }

  return Drawer(
    backgroundColor: const Color(0xFF71BB7B),
    child: Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfilePage(title: 'Profile'),
              ),
            );
          },
          child: DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF71BB7B)),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/dummy.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hello, $username',
                    style: const TextStyle(
                      color: Color(0xFFFAF4E8),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.notifications,
                  color: Color(0xFFFAF4E8),
                ),
                title: const Text('Notifications'),
                textColor: const Color(0xFFFAF4E8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const NotificationPage(title: 'Notifications'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: Color(0xFFFAF4E8)),
                title: const Text('Community'),
                textColor: const Color(0xFFFAF4E8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const PlaceholderPage(title: 'Community List'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Color(0xFFFAF4E8)),
                title: const Text('Help Requests'),
                textColor: const Color(0xFFFAF4E8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const PlaceholderPage(title: 'Help Requests'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Color(0xFFFAF4E8)),
                title: const Text('Help History'),
                textColor: const Color(0xFFFAF4E8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const PlaceholderPage(title: 'Help History'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback, color: Color(0xFFFAF4E8)),
                title: const Text('Report & Feedback'),
                textColor: const Color(0xFFFAF4E8),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const PlaceholderPage(title: 'Report & Feedback'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(
          color: Color(0xFFFAF4E8),
          thickness: 1,
          indent: 16,
          endIndent: 16,
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Color(0xFFFAF4E8)),
          title: const Text('Log Out'),
          textColor: const Color(0xFFFAF4E8),
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Confirm Logout"),
                    content: const Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Color(0xFF71BB7B)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF71BB7B),
                        ),
                        onPressed: signOut,
                        child: const Text(
                          "Log Out",
                          style: TextStyle(color: Color(0xFFFAF4E8)),
                        ),
                      ),
                    ],
                  ),
            );
          },
        ),
      ],
    ),
  );
}
