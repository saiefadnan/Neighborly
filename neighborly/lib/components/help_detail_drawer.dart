import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class HelpDetailDrawer extends StatelessWidget {
  final Map<String, dynamic> helpData;

  const HelpDetailDrawer({super.key, required this.helpData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40), // Leave space for close button
                  Text("Help Details", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),

                  Text("Urgency: ${helpData['type']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),

                  Text("Time: ${helpData['time'] ?? 'Not specified'}"),
                  const SizedBox(height: 5),

                  Text("Help Type: ${helpData['helpType'] ?? 'Not specified'}"),
                  const SizedBox(height: 5),

                  Text("Description: ${helpData['description'] ?? 'No description'}"),
                  const SizedBox(height: 5),

                  if (helpData['location'] != null && helpData['location'] is LatLng)
                    Text(
                      "Location: Lat ${helpData['location'].latitude.toStringAsFixed(5)}, "
                      "Lng ${helpData['location'].longitude.toStringAsFixed(5)}",
                    ),

                  const SizedBox(height: 10),

                  if (helpData['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: helpData['image'] is String
                          ? Image.network(helpData['image'], height: 150, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(helpData['image'], height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Accept Help Request"),
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close',
            ),
          ),
        ],
      ),
    );
  }
}
