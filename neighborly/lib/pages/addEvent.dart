import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:neighborly/components/snackbar.dart';
import 'package:neighborly/functions/media_upload.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  final String title;
  const CreateEventPage({super.key, required this.title});

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  DateTime selectedDate = DateTime.now();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  GoogleMapController? mapController;
  final ImagePicker imagePicker = ImagePicker();
  File? imagepath;
  String eventType = '';
  double notifRange = 5;
  bool isLoading = false;
  List<Map<String, String>> eventTypes = [
    {"title": "Tree Plantation", "desc": "Join a green cause."},
    {"title": "Invitation Party", "desc": "Celebrate and invite friends."},
    {"title": "Community Clean-Up", "desc": "Help clean the neighborhood."},
    {"title": "Food Drive", "desc": "Donate and distribute food."},
    {"title": "Block Party", "desc": "Fun gathering with the block."},
  ]; // Default to San Francisco

  Future<void> storeEvents() async {
    setState(() {
      isLoading = true;
    });
    try {
      String lngStr = selectedLocation.longitude.toStringAsFixed(6);
      String latStr = selectedLocation.latitude.toStringAsFixed(6);
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl = await uploadFile(imagepath);
      final event = {
        'title': titleController.text.trim(),
        'desc': descriptionController.text.trim(),
        'img':
            imageUrl ??
            'https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651567/tegan-mierle-fDostElVhN8-unsplash_kackpp.jpg',
        'joined': 'true',
        'createdBy': uid,
        'date': dateController.text.trim(),
        'location': locationController.text.trim(),
        'lng': double.tryParse(lngStr) ?? 0.0,
        'lat': double.tryParse(latStr) ?? 0.0,
        'tags': ['#community', '#event'],
      };
      events.add(event);
      await FirebaseFirestore.instance.collection('events').add(event);

      // After adding event
      Navigator.pop(context, events);
      showSnackBarSuccess(context, 'Event creation succeed');
    } catch (e) {
      showSnackBarError(context, 'Event creation failed');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickImage() async {
    final image = await imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imagepath = File(image.path);
      });
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
      controller.text = "${pickedDate.toLocal()}".split(' ')[0];
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
        print(selectedDate);
        // If the selected date is today, ensure the time is not in the past
        if (pickedTime.hour < currentTime.hour ||
            (pickedTime.hour == currentTime.hour &&
                pickedTime.minute < currentTime.minute)) {
          showSnackBarError(
            context,
            'Please select a time later than the current time.',
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
  LatLng selectedLocation = LatLng(23.8103, 90.4125);
  List<Map<String, dynamic>> events = [];

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
    mapController?.dispose();
    imagepath = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: const Color(
          0xFF71BB7B,
        ), // Updated to match the green shade
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Notification Range"),
                    Slider(
                      value: notifRange,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: "${notifRange.toInt()} km",
                      onChanged:
                          (val) => setState(() {
                            notifRange = val;
                          }),
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
                            eventType == event["title"]
                                ? const Color(
                                  0xFFE8F5E9,
                                ) // Light green for selected cards
                                : null,
                        child: GestureDetector(
                          child: ListTile(
                            title: Text(event["title"]!),
                            subtitle: Text(event["desc"]!),
                            onTap: () {
                              eventType = event["title"] ?? "";
                              setState(() {
                                titleController.text = event['title']!;
                                descriptionController.text = event['desc']!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildTextField(
                      "Event Title",
                      titleController,
                      icon: Icons.event,
                    ),
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
                    Column(
                      children: [
                        // Wrap FlutterMap in a fixed height container if needed:
                        SizedBox(
                          height: 400, // fix height to avoid layout issues
                          child: GoogleMap(
                            gestureRecognizers:
                                <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<OneSequenceGestureRecognizer>(
                                    () => EagerGestureRecognizer(),
                                  ),
                                },
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation,
                              zoom: 12,
                            ),
                            onMapCreated:
                                (controller) => mapController = controller,
                            markers: {
                              Marker(
                                markerId: MarkerId('selected-location'),
                                position: selectedLocation,
                              ),
                            },
                            onTap: (newPosition) {
                              setState(() {
                                selectedLocation = newPosition;
                              });
                              getPlaceName(selectedLocation);
                            },
                            mapType: MapType.normal,
                            myLocationEnabled:
                                true, // Disable if you don't need it
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: false, // You already have this
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                            rotateGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: false, // Disable
                          ),
                        ),
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
                            imagepath != null
                                ? Stack(
                                  children: [
                                    SizedBox(
                                      height: 300,
                                      width: double.infinity,
                                      child: Image.file(
                                        imagepath!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            imagepath = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
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
                        onPressed: storeEvents,
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
        onTap: () {
          if (dateController.text.trim().isEmpty) {
            showSnackBarError(context, "Please select a date");
            return;
          }
          _pickTime(
            context,
            controller,
            DateTime.parse(dateController.text),
          ); //
        },
      ),
    );
  }
}
