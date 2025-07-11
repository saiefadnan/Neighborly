import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:neighborly/pages/forum.dart';

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
            markers: helpRequests.map((req) {
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
              builder: (context) => ForumPage(title: 'Community Forum'),
            ),
            );
            },
            child: Icon(Icons.message),
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "addHelp",
            onPressed: () {
              // TODO: Open bottom drawer to create help request
            },
            child: Icon(Icons.add),
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: const Color(0xFFFAF4E8),
          ),
        ],
      ),
      appBar: AppBar(
        title: Text("Neighborly"),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            //TODO: Open drawer menu
          },
        ),
      ),
    );
  }
}
