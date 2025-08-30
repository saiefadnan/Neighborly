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
import 'package:neighborly/functions/event_notifier.dart';
import 'package:neighborly/functions/media_upload.dart';
import 'package:neighborly/models/event.dart';

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
  final TextEditingController tagsController = TextEditingController();
  GoogleMapController? mapController;
  final ImagePicker imagePicker = ImagePicker();
  File? imagepath;
  String eventType = '';
  double notifRange = 5;
  bool isLoading = false;
  List<String> selectedTags = [];
  List<Map<String, String>> eventTypes = [
    {"title": "Tree Plantation", "desc": "Join a green cause."},
    {"title": "Invitation Party", "desc": "Celebrate and invite friends."},
    {"title": "Community Clean-Up", "desc": "Help clean the neighborhood."},
    {"title": "Food Drive", "desc": "Donate and distribute food."},
    {"title": "Block Party", "desc": "Fun gathering with the block."},
  ]; // Default to San Francisco

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
    tagsController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    mapController?.dispose();
    imagepath = null;
    super.dispose();
  }

  // Validation function to check if all required fields are filled
  String? _validateFields() {
    if (titleController.text.trim().isEmpty) {
      return 'Please enter an event title';
    }
    if (dateController.text.trim().isEmpty) {
      return 'Please select a date';
    }
    if (timeController.text.trim().isEmpty) {
      return 'Please select a time';
    }
    if (locationController.text.trim().isEmpty) {
      return 'Please select a location on the map';
    }
    if (descriptionController.text.trim().isEmpty) {
      return 'Please enter a description';
    }
    return null; // All fields are valid
  }

  // Check if all required fields are filled (for UI state)
  bool get _areAllFieldsFilled {
    return titleController.text.trim().isNotEmpty &&
        dateController.text.trim().isNotEmpty &&
        timeController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty;
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
                    // Helper text for required fields
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Fields marked with * are required',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      "Event Title *",
                      titleController,
                      icon: Icons.event,
                    ),
                    _buildDatePickerField(
                      "Date *",
                      dateController,
                      context,
                      icon: Icons.calendar_today,
                    ),
                    _buildTimePickerField(
                      "Time *",
                      timeController,
                      context,
                      selectedDate,
                      icon: Icons.access_time,
                    ),
                    _buildTextField(
                      "Location *",
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
                      "Description *",
                      descriptionController,
                      maxLines: 3,
                      icon: Icons.description,
                    ),

                    const SizedBox(height: 12),
                    _buildTagsField(),

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
                          backgroundColor:
                              _areAllFieldsFilled
                                  ? const Color(0xFF71BB7B)
                                  : Colors
                                      .grey, // Dynamic color based on field completion
                        ),
                        onPressed: () async {
                          // Validate all required fields
                          final validationError = _validateFields();
                          if (validationError != null) {
                            showSnackBarError(context, validationError);
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final imageUrl = await uploadFile(imagepath);
                            final docRef =
                                FirebaseFirestore.instance
                                    .collection('events')
                                    .doc();
                            ref
                                .watch(eventProvider.notifier)
                                .addEvents(
                                  EventModel(
                                    id: docRef.id,
                                    title: titleController.text.trim(),
                                    description:
                                        descriptionController.text.trim(),
                                    imageUrl: imageUrl,
                                    approved: true,
                                    createdAt: Timestamp.now(),
                                    location: locationController.text.trim(),
                                    lng: selectedLocation.longitude,
                                    lat: selectedLocation.latitude,
                                    raduis: notifRange,
                                    tags:
                                        selectedTags.isNotEmpty
                                            ? selectedTags
                                            : ['#community', '#event'],
                                  ),
                                  docRef,
                                );
                            showSnackBarSuccess(
                              context,
                              "Event added successfully",
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            showSnackBarError(
                              context,
                              "Error creating event: ${e.toString()}",
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        child: Text(
                          _areAllFieldsFilled
                              ? "Create Event"
                              : "Fill All Required Fields",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTagsField() {
    final List<String> predefinedTags = [
      '#community',
      '#event',
      '#fun',
      '#education',
      '#sports',
      '#charity',
      '#environment',
      '#culture',
      '#networking',
      '#volunteer',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tag, color: Color(0xFF71BB7B)),
            const SizedBox(width: 8),
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF71BB7B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Add custom tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagsController,
                decoration: InputDecoration(
                  hintText: 'Add custom tag (press Enter)',
                  prefixText: '#',
                  filled: true,
                  fillColor: const Color(0xFFE8F5E9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF71BB7B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF71BB7B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF71BB7B),
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    final tag = '#${value.trim().replaceAll('#', '')}';
                    if (!selectedTags.contains(tag)) {
                      setState(() {
                        selectedTags.add(tag);
                        tagsController.clear();
                      });
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final value = tagsController.text.trim();
                if (value.isNotEmpty) {
                  final tag = '#${value.replaceAll('#', '')}';
                  if (!selectedTags.contains(tag)) {
                    setState(() {
                      selectedTags.add(tag);
                      tagsController.clear();
                    });
                  }
                }
              },
              icon: const Icon(Icons.add, color: Color(0xFF71BB7B)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Predefined tags
        const Text(
          'Popular Tags:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              predefinedTags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedTags.remove(tag);
                      } else {
                        selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF71BB7B)
                              : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF71BB7B)
                                : Colors.grey[400]!,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: 12),

        // Selected tags display
        if (selectedTags.isNotEmpty) ...[
          const Text(
            'Selected Tags:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71BB7B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                selectedTags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTags.remove(tag);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
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
