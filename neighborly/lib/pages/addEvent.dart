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
import 'package:neighborly/notifiers/event_notifier.dart';
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
        setState(() {
          locationController.text =
              '${place.name}, ${place.locality}, ${place.country}';
        });
        print('Location set: ${locationController.text}'); // Debug log
      } else {
        setState(() {
          locationController.text = 'Unknown location';
        });
      }
    } catch (e) {
      setState(() {
        locationController.text = 'Error fetching location';
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to update button state when fields change
    titleController.addListener(_updateButtonState);
    dateController.addListener(_updateButtonState);
    timeController.addListener(_updateButtonState);
    locationController.addListener(_updateButtonState);
    descriptionController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      // This will trigger a rebuild and update the button appearance
    });
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    titleController.removeListener(_updateButtonState);
    dateController.removeListener(_updateButtonState);
    timeController.removeListener(_updateButtonState);
    locationController.removeListener(_updateButtonState);
    descriptionController.removeListener(_updateButtonState);

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
    final titleFilled = titleController.text.trim().isNotEmpty;
    final dateFilled = dateController.text.trim().isNotEmpty;
    final timeFilled = timeController.text.trim().isNotEmpty;
    final locationFilled = locationController.text.trim().isNotEmpty;
    final descriptionFilled = descriptionController.text.trim().isNotEmpty;

    final allFilled =
        titleFilled &&
        dateFilled &&
        timeFilled &&
        locationFilled &&
        descriptionFilled;

    // Debug logging
    print('=== BUTTON STATE CHECK ===');
    print('Title filled: $titleFilled (${titleController.text.trim()})');
    print('Date filled: $dateFilled (${dateController.text.trim()})');
    print('Time filled: $timeFilled (${timeController.text.trim()})');
    print(
      'Location filled: $locationFilled (${locationController.text.trim()})',
    );
    print(
      'Description filled: $descriptionFilled (${descriptionController.text.trim()})',
    );
    print('All fields filled: $allFilled');
    print('========================');

    return allFilled;
  }

  // Get icon for event type
  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case "Tree Plantation":
        return Icons.eco_rounded;
      case "Invitation Party":
        return Icons.celebration_rounded;
      case "Community Clean-Up":
        return Icons.cleaning_services_rounded;
      case "Food Drive":
        return Icons.restaurant_rounded;
      case "Block Party":
        return Icons.party_mode_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Create Event',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          isLoading
              ? Container(
                decoration: const BoxDecoration(color: Color(0xFFFAF8F5)),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF71BB7B),
                        ),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Creating your event...",
                        style: TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Helper text for required fields
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF71BB7B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF71BB7B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Fields marked with * are required',
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Notification Range Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people_rounded,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Event Range",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "People within ${notifRange.toInt()} km can join this event",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5F6368),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF71BB7B),
                              inactiveTrackColor: const Color(
                                0xFF71BB7B,
                              ).withOpacity(0.2),
                              thumbColor: const Color(0xFF71BB7B),
                              overlayColor: const Color(
                                0xFF71BB7B,
                              ).withOpacity(0.2),
                              valueIndicatorColor: const Color(0xFF71BB7B),
                              trackHeight: 4,
                            ),
                            child: Slider(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Templates Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Event Templates',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Event type cards
                          ...eventTypes.map(
                            (event) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color:
                                    eventType == event["title"]
                                        ? const Color(
                                          0xFF71BB7B,
                                        ).withOpacity(0.1)
                                        : const Color(0xFFFAF8F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      eventType == event["title"]
                                          ? const Color(0xFF71BB7B)
                                          : const Color(
                                            0xFF71BB7B,
                                          ).withOpacity(0.2),
                                  width: eventType == event["title"] ? 2 : 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    eventType = event["title"] ?? "";
                                    setState(() {
                                      titleController.text = event['title']!;
                                      descriptionController.text =
                                          event['desc']!;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                eventType == event["title"]
                                                    ? const Color(0xFF71BB7B)
                                                    : const Color(
                                                      0xFF71BB7B,
                                                    ).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            _getEventIcon(event["title"]!),
                                            color:
                                                eventType == event["title"]
                                                    ? Colors.white
                                                    : const Color(0xFF71BB7B),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event["title"]!,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color:
                                                      eventType ==
                                                              event["title"]
                                                          ? const Color(
                                                            0xFF71BB7B,
                                                          )
                                                          : const Color(
                                                            0xFF2C3E50,
                                                          ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                event["desc"]!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF5F6368),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (eventType == event["title"])
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF71BB7B),
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Event Details',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                            "Description *",
                            descriptionController,
                            maxLines: 3,
                            icon: Icons.description,
                          ),
                          _buildTextField(
                            "Location *",
                            locationController,
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Map Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Location',
                                      style: TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Tap on the map to set event location',
                                      style: TextStyle(
                                        color: Color(0xFF5F6368),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 450,
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
                                    markerId: const MarkerId(
                                      'selected-location',
                                    ),
                                    position: selectedLocation,
                                    infoWindow: const InfoWindow(
                                      title: 'Event Location',
                                    ),
                                  ),
                                },
                                onTap: (newPosition) {
                                  setState(() {
                                    selectedLocation = newPosition;
                                  });
                                  getPlaceName(selectedLocation);
                                },
                                mapType: MapType.normal,
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                                compassEnabled: false,
                                rotateGesturesEnabled: true,
                                scrollGesturesEnabled: true,
                                zoomGesturesEnabled: true,
                                tiltGesturesEnabled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTagsField(),

                    SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image_rounded,
                                  color: Color(0xFF71BB7B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Event Image',
                                      style: TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Add a photo to make your event more appealing',
                                      style: TextStyle(
                                        color: Color(0xFF5F6368),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              height: 400,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF8F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child:
                                  imagepath != null
                                      ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: SizedBox(
                                              height: 400,
                                              width: double.infinity,
                                              child: Image.file(
                                                imagepath!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  imagepath = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      blurRadius: 4,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.redAccent,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF71BB7B,
                                              ).withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.add_a_photo_rounded,
                                              size: 32,
                                              color: Color(0xFF71BB7B),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Tap to add event image',
                                            style: TextStyle(
                                              color: Color(0xFF5F6368),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Create Event Button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow:
                            _areAllFieldsFilled
                                ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF71BB7B,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : [],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _areAllFieldsFilled
                                  ? const Color(0xFF71BB7B)
                                  : Colors.grey[400],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed:
                            _areAllFieldsFilled
                                ? () async {
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
                                    String imageUrl = '';
                                    if (imagepath != null) {
                                      imageUrl = await uploadFile(imagepath);
                                    }

                                    EventModel newEvent = EventModel(
                                      id: '',
                                      creatorId:
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid ??
                                          '',
                                      title: titleController.text.trim(),
                                      description:
                                          descriptionController.text.trim(),
                                      imageUrl: imageUrl,
                                      date: () {
                                        // Parse the time from the controller
                                        final timeParts = timeController.text
                                            .trim()
                                            .split(' ');
                                        final time = timeParts[0].split(':');
                                        int hour = int.parse(time[0]);
                                        int minute = int.parse(time[1]);

                                        // Handle AM/PM
                                        if (timeParts.length > 1 &&
                                            timeParts[1].toUpperCase() ==
                                                'PM' &&
                                            hour != 12) {
                                          hour += 12;
                                        } else if (timeParts.length > 1 &&
                                            timeParts[1].toUpperCase() ==
                                                'AM' &&
                                            hour == 12) {
                                          hour = 0;
                                        }

                                        return DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                          hour,
                                          minute,
                                        );
                                      }(),
                                      approved: true,
                                      createdAt: Timestamp.now(),
                                      location: locationController.text.trim(),
                                      lng: selectedLocation.longitude,
                                      lat: selectedLocation.latitude,
                                      radius: notifRange,
                                      tags:
                                          selectedTags.isNotEmpty
                                              ? selectedTags
                                              : [],
                                    );
                                    ref
                                        .watch(eventProvider.notifier)
                                        .storeEvents(newEvent);
                                    ref
                                        .watch(eventProvider.notifier)
                                        .addEvents(newEvent);
                                    if (!context.mounted) return;
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
                                }
                                : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _areAllFieldsFilled
                                  ? Icons.add_rounded
                                  : Icons.warning_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _areAllFieldsFilled
                                  ? "Create Event"
                                  : "Fill All Required Fields",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF71BB7B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: label != "Location *",
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F6368),
            ),
            prefixIcon:
                icon != null
                    ? Icon(icon, color: const Color(0xFF71BB7B), size: 20)
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
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
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF71BB7B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F6368),
            ),
            prefixIcon:
                icon != null
                    ? Icon(icon, color: const Color(0xFF71BB7B), size: 20)
                    : null,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF71BB7B),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
          onTap: () => _pickDate(context, controller),
        ),
      ),
    );
  }

  Widget _buildTimePickerField(
    String label,
    TextEditingController controller,
    BuildContext context,
    DateTime selectedDate, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF71BB7B).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5F6368),
            ),
            prefixIcon:
                icon != null
                    ? Icon(icon, color: const Color(0xFF71BB7B), size: 20)
                    : null,
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF71BB7B),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          ),
          onTap: () {
            if (dateController.text.trim().isEmpty) {
              showSnackBarError(context, "Please select a date first");
              return;
            }
            _pickTime(context, controller, DateTime.parse(dateController.text));
          },
        ),
      ),
    );
  }
}
