import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:neighborly/components/snackbar.dart';
import 'package:neighborly/models/event.dart';

final notificationRangeProvider = StateProvider<double>((ref) => 5.0);
final selectedEventTypeProvider = StateProvider<String?>((ref) => null);
final pickedImageProvider = StateProvider<String?>((ref) => null);

class CreateEventPage extends ConsumerStatefulWidget {
  final String title;
  const CreateEventPage({super.key, required this.title});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  DateTime selectedDate = DateTime.now();

  List<Map<String, String>> eventTypes = [
    {"title": "Tree Plantation", "desc": "Join a green cause."},
    {"title": "Invitation Party", "desc": "Celebrate and invite friends."},
    {"title": "Community Clean-Up", "desc": "Help clean the neighborhood."},
    {"title": "Food Drive", "desc": "Donate and distribute food."},
    {"title": "Block Party", "desc": "Fun gathering with the block."},
  ]; // Default to San Francisco

  Future<void> pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(pickedImageProvider.notifier).state = image.path;
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now, // Restrict to current date or later
      lastDate: DateTime(2100), // Set an upper limit for the date picker
    );

    if (pickedDate != null) {
      selectedDate = pickedDate;
      controller.text =
          "${pickedDate.toLocal()}".split(' ')[0]; // Format the date as needed
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    TextEditingController controller,
    DateTime selectedDate,
  ) async {
    final DateTime now = DateTime.now();
    final TimeOfDay currentTime = TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime != null) {
      // Check if the selected date is today
      if (selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day) {
        // If the selected date is today, ensure the time is not in the past
        if (pickedTime.hour < currentTime.hour ||
            (pickedTime.hour == currentTime.hour &&
                pickedTime.minute < currentTime.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please select a time later than the current time.',
              ),
            ),
          );
          return;
        }
      }

      // Update the controller with the selected time
      final formattedTime = pickedTime.format(
        context,
      ); // Format the time as needed
      controller.text = formattedTime;
    }
  }

  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  LatLng selectedLocation = LatLng(
    37.7749,
    -122.4194,
  ); // Default to San Francisco

  // void _updateLocation() {
  //   final double? latitude = double.tryParse(latitudeController.text);
  //   final double? longitude = double.tryParse(longitudeController.text);

  //   if (latitude != null && longitude != null) {
  //     setState(() {
  //       selectedLocation = LatLng(latitude, longitude);
  //     });
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Invalid latitude or longitude')),
  //     );
  //   }
  // }
  void _onMapTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      selectedLocation = latlng;
    });
    getPlaceName(selectedLocation);
  }

  Future<void> getPlaceName(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // return
        setState(() {
          locationController.text =
              '${place.name}, ${place.locality}, ${place.country}';
        });
      } else {
        setState(() {
          locationController.text = 'Unknown location';
        });
        // return
      }
    } catch (e) {
      // return
      setState(() {
        locationController.text = 'Error fetching location';
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    timeController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedEventTypeProvider);
    final range = ref.watch(notificationRangeProvider);
    final imagePath = ref.watch(pickedImageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: const Color(
          0xFF71BB7B,
        ), // Updated to match the green shade
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Notification Range"),
            Slider(
              value: range,
              min: 1,
              max: 50,
              divisions: 49,
              label: "${range.toInt()} km",
              onChanged:
                  (val) =>
                      ref.read(notificationRangeProvider.notifier).state = val,
            ),
            const SizedBox(height: 12),
            Text(
              'Templates ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            // Event type cards
            ...eventTypes.map(
              (event) => Card(
                color:
                    selectedType == event["title"]
                        ? const Color(
                          0xFFE8F5E9,
                        ) // Light green for selected cards
                        : null,
                child: GestureDetector(
                  child: ListTile(
                    title: Text(event["title"]!),
                    subtitle: Text(event["desc"]!),
                    onTap: () {
                      ref.read(selectedEventTypeProvider.notifier).state =
                          event["title"];
                      setState(() {
                        titleController.text = event['title']!;
                        descriptionController.text = event['desc']!;
                      });
                    },
                    // trailing: ElevatedButton(
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: const Color(
                    //       0xFF71BB7B,
                    //     ), // Button color updated
                    //   ),
                    //   onPressed: () {
                    //     ref.read(selectedEventTypeProvider.notifier).state =
                    //         event["title"];
                    //     setState(() {
                    //       titleController.text = event['title']!;
                    //       descriptionController.text = event['desc']!;
                    //     });
                    //   },
                    //   child: const Text("Select"),
                    // ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildTextField("Event Title", titleController, icon: Icons.event),
            _buildDatePickerField(
              "Date",
              dateController,
              context,
              icon: Icons.calendar_today,
            ),
            _buildTimePickerField(
              "Time",
              timeController,
              context,
              selectedDate,
              icon: Icons.access_time,
            ),
            _buildTextField(
              "Location",
              locationController,
              icon: Icons.location_on,
            ),

            const SizedBox(height: 12),
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: TextField(
            //           controller: latitudeController,
            //           decoration: const InputDecoration(
            //             labelText: 'Latitude',
            //             border: OutlineInputBorder(),
            //           ),
            //           keyboardType: TextInputType.number,
            //         ),
            //       ),
            //       const SizedBox(width: 8),
            //       Expanded(
            //         child: TextField(
            //           controller: longitudeController,
            //           decoration: const InputDecoration(
            //             labelText: 'Longitude',
            //             border: OutlineInputBorder(),
            //           ),
            //           keyboardType: TextInputType.number,
            //         ),
            //       ),
            //       const SizedBox(width: 8),
            //       ElevatedButton(
            //         onPressed: _updateLocation,
            //         child: const Text('Set Location'),
            //       ),
            //     ],
            //   ),
            // ),

            // Leaflet Map Widget
            // Replace this:

            // Expanded(
            //   child: FlutterMap(
            //     options: MapOptions(
            //       initialCenter: selectedLocation,
            //       initialZoom: 10,
            //     ),
            //     layers: [
            //       TileLayerOptions(
            //         urlTemplate:
            //             'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            //         subdomains: ['a', 'b', 'c'],
            //       ),
            //       MarkerLayerOptions(
            //         markers: [
            //           Marker(
            //             point: selectedLocation,
            //             builder:
            //                 (ctx) => const Icon(
            //                   Icons.location_on,
            //                   color: Colors.red,
            //                   size: 40,
            //                 ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),

            // With this:
            Column(
              children: [
                // Wrap FlutterMap in a fixed height container if needed:
                SizedBox(
                  height: 300, // fix height to avoid layout issues
                  child: FlutterMap(
                    options: MapOptions(
                      center: selectedLocation,
                      zoom: 10,
                      onTap: _onMapTap, // your tap handler
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: selectedLocation,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Text(
                //     'Selected Location: ${selectedLocation.latitude}, ${selectedLocation.longitude}',
                //     style: const TextStyle(fontSize: 16),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              "Description",
              descriptionController,
              maxLines: 3,
              icon: Icons.description,
            ),

            const SizedBox(height: 12),
            const Text("Optional Image"),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[200],
                child:
                    imagePath != null
                        ? Stack(
                          children: [
                            SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () {
                                  ref.read(pickedImageProvider.notifier).state =
                                      null; // Clear the image.
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF71BB7B,
                  ), // Updated button color
                ),
                onPressed: () {
                  String lngStr = selectedLocation.longitude.toStringAsFixed(6);
                  String latStr = selectedLocation.latitude.toStringAsFixed(6);

                  events.add({
                    'title': titleController.text.trim(),
                    'desc': descriptionController.text.trim(),
                    'img':
                        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
                    'joined': 'true',
                    'date': dateController.text.trim(),
                    'location': locationController.text.trim(),
                    'lng': double.tryParse(lngStr) ?? 0.0,
                    'lat': double.tryParse(latStr) ?? 0.0,
                    'tags': ['#community', '#event'],
                  });

                  // After adding event
                  Navigator.pop(context, events);
                  showSnackBarSuccess(context, 'Event creation succeed');
                },
                child: const Text("Create Event"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon, // Optional icon parameter
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: label != "Location",
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF71BB7B), // Updated label color
          ),
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF71BB7B)) : null,
          filled: true,
          fillColor: const Color(0xFFE8F5E9), // Light green background
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B), width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    BuildContext context, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF71BB7B),
          ),
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF71BB7B)) : null,
          filled: true,
          fillColor: const Color(0xFFE8F5E9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B), width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap: () => _pickDate(context, controller),
      ),
    );
  }

  Widget _buildTimePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
    DateTime selectedDate, { // Added selectedDate as a parameter
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF71BB7B),
          ),
          prefixIcon:
              icon != null ? Icon(icon, color: const Color(0xFF71BB7B)) : null,
          filled: true,
          fillColor: const Color(0xFFE8F5E9),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF71BB7B), width: 2),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap:
            () => _pickTime(
              context,
              controller,
              selectedDate,
            ), // Pass selectedDate here
      ),
    );
  }
}
