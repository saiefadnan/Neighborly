import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/pages/forum.dart';
import 'package:neighborly/pages/notification.dart';
import 'package:neighborly/pages/profile.dart';
import 'package:neighborly/components/help_request_drawer.dart';
import 'package:neighborly/components/help_detail_drawer.dart';
import 'package:neighborly/pages/placeHolder.dart';
import 'chat_screen.dart';

class MapHomePage extends ConsumerStatefulWidget {
  @override
  _MapHomePageState createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
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
          initialCenter: LatLng(23.8103, 90.4125),
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
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => HelpDetailDrawer(helpData: req),
                        );
                      },
                      child: Tooltip(
                        message: req['description'],
                        child: Icon(
                          Icons.location_pin,
                          color: getMarkerColor(req['type']),
                          size: 36,
                        ),
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
    context.go('/signin');
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
                        child: const Text(
                          "Log Out",
                          style: TextStyle(color: Color(0xFFFAF4E8)),
                        ),
                        onPressed: signOut,
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
