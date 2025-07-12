import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/pages/notification.dart';
import 'package:neighborly/pages/profile.dart';

class MapHomePage extends StatelessWidget {
  final List<Map<String, dynamic>> helpRequests = [
    {
      "type": "Emergency",
      "location": LatLng(23.8103, 90.4125),
      "description": "Medical emergency near Dhanmondi",
    },
    {
      "type": "Urgent",
      "location": LatLng(23.8115, 90.4090),
      "description": "Need groceries for elder person",
    },
    {
      "type": "General",
      "location": LatLng(23.8127, 90.4150),
      "description": "Looking for direction to new clinic",
    },
  ];

  Color getMarkerColor(String type) {
    switch (type) {
      case "Emergency":
        return Colors.red;
      case "Urgent":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(23.8103, 90.4125), // Center on Dhaka
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.neighborly',
          ),
          MarkerLayer(
            markers:
                helpRequests.map((req) {
                  return Marker(
                    point: req['location'],
                    width: 40,
                    height: 40,
                    child: Tooltip(
                      message: req['description'],
                      child: Icon(
                        Icons.location_pin,
                        color: getMarkerColor(req['type']),
                        size: 36,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            child: Icon(Icons.forum),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "addHelp",
            onPressed: () {
              // TODO: Open bottom drawer to create help request
            },
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
            child: Icon(Icons.add),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text("Neighborly"),
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
      drawer: _buildDrawer(context),
    );
  }
}

Widget _buildDrawer(BuildContext context) {
  String username = "Ali";

  return Drawer(
    backgroundColor: const Color(0xFF71BB7B),
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close the drawer first
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
        ListTile(
          leading: const Icon(Icons.notifications, color: Color(0xFFFAF4E8)),
          title: const Text('Notifications'),
          textColor: Color(0xFFFAF4E8),
          onTap: () {
            // Close drawer first
            Navigator.pop(context);
            // Navigate to notifications page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const NotificationPage(title: 'Notifications'),
              ),
            );
          },
        ),
        // 🔜 Add more options here In Sha Allah
      ],
    ),
  );
}
