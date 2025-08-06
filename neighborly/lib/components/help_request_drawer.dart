import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class HelpRequestDrawer extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  const HelpRequestDrawer({super.key, required this.onSubmit});

  @override
  HelpRequestDrawerState createState() => HelpRequestDrawerState();
}

class HelpRequestDrawerState extends State<HelpRequestDrawer> {
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController();
  final _usernameController = TextEditingController(text: 'Ali');
  final _addressController = TextEditingController(
    text: '123, Dhanmondi, Dhaka',
  );
  String _urgency = 'Emergency';
  String _helpType = 'Medical';
  File? _image;

  final _urgencies = ['Emergency', 'Urgent', 'General'];
  final _helpTypes = [
    'Medical',
    'Fire',
    'Shifting House',
    'Grocery',
    'Traffic Update',
    'Route',
    'Shifting Furniture',
    'Lost Person',
    'Lost Item/Pet',
  ];

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounce;
  LatLng? _selectedLocation;

  // Local Bangladesh locations as fallback
  final List<Map<String, dynamic>> _localLocations = [
    {'name': 'Dhaka', 'lat': 23.8103, 'lon': 90.4125, 'type': 'city'},
    {'name': 'Chittagong', 'lat': 22.3569, 'lon': 91.7832, 'type': 'city'},
    {'name': 'Sylhet', 'lat': 24.8949, 'lon': 91.8687, 'type': 'city'},
    {'name': 'Rajshahi', 'lat': 24.3745, 'lon': 88.6042, 'type': 'city'},
    {'name': 'Khulna', 'lat': 22.8456, 'lon': 89.5403, 'type': 'city'},
    {'name': 'Barisal', 'lat': 22.7010, 'lon': 90.3535, 'type': 'city'},
    {'name': 'Rangpur', 'lat': 25.7439, 'lon': 89.2752, 'type': 'city'},
    {'name': 'Mymensingh', 'lat': 24.7471, 'lon': 90.4203, 'type': 'city'},
    {'name': 'Dhanmondi', 'lat': 23.7461, 'lon': 90.3742, 'type': 'area'},
    {'name': 'Gulshan', 'lat': 23.7808, 'lon': 90.4134, 'type': 'area'},
    {'name': 'Uttara', 'lat': 23.8759, 'lon': 90.3795, 'type': 'area'},
    {'name': 'Mirpur', 'lat': 23.8223, 'lon': 90.3654, 'type': 'area'},
    {'name': 'Banani', 'lat': 23.7937, 'lon': 90.4066, 'type': 'area'},
    {'name': 'Motijheel', 'lat': 23.7337, 'lon': 90.4178, 'type': 'area'},
    {'name': 'Old Dhaka', 'lat': 23.7104, 'lon': 90.4074, 'type': 'area'},
    {'name': 'Wari', 'lat': 23.7183, 'lon': 90.4206, 'type': 'area'},
    {'name': 'Ramna', 'lat': 23.7358, 'lon': 90.3964, 'type': 'area'},
    {'name': 'Tejgaon', 'lat': 23.7694, 'lon': 90.3917, 'type': 'area'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitRequest() async {
    final String address = _addressController.text.trim();
    final String time = _timeController.text.trim();
    final String description = _descriptionController.text.trim();

    if (address.isEmpty || time.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      LatLng coordinates;

      if (_selectedLocation != null) {
        // Use the selected location from search
        coordinates = _selectedLocation!;
      } else {
        // Fallback to geocoding the address
        List<Location> locations = await locationFromAddress(address);
        if (locations.isEmpty) throw Exception("No location found");
        coordinates = LatLng(
          locations.first.latitude,
          locations.first.longitude,
        );
      }

      final helpData = {
        "type": _urgency,
        "location": coordinates,
        "description": description,
        "time": time,
        "title": _helpType,
        "priority": _urgency.toLowerCase(),
        "address": address,
        "image": _image,
      };

      widget.onSubmit(helpData);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Help request submitted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid address. Please try again.")),
      );
    }
  }

  void _onAddressChanged(String input) {
    // Cancel previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Clear suggestions if input is too short
    if (input.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    // For very short inputs, search locally immediately
    if (input.length == 2) {
      setState(() {
        _suggestions = _getLocalMatches(input);
        _isLoadingSuggestions = false;
      });
      return;
    }

    // Set up debounce timer with shorter delay for better responsiveness
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fetchAddressSuggestions(input);
      }
    });
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() => _isLoadingSuggestions = true);
    print('Fetching suggestions for: $input');

    try {
      // First, try local Bangladesh locations
      List<Map<String, dynamic>> localMatches = _getLocalMatches(input);

      // Try to fetch from Photon API (free, no API key, better rate limits)
      List<Map<String, dynamic>> apiSuggestions = await _fetchFromPhotonAPI(
        input,
      );

      // If Photon fails, try LocationIQ free tier
      if (apiSuggestions.isEmpty) {
        apiSuggestions = await _fetchFromLocationIQ(input);
      }

      // Combine local and API results, prioritizing local matches
      List<Map<String, dynamic>> combinedSuggestions = [...localMatches];

      // Add API suggestions that don't duplicate local ones
      for (var apiSuggestion in apiSuggestions) {
        bool isDuplicate = localMatches.any(
          (local) =>
              local['display_name'].toLowerCase().contains(
                apiSuggestion['main_text'].toLowerCase(),
              ) ||
              apiSuggestion['main_text'].toLowerCase().contains(
                local['name'].toLowerCase(),
              ),
        );

        if (!isDuplicate && combinedSuggestions.length < 8) {
          combinedSuggestions.add(apiSuggestion);
        }
      }

      setState(() {
        _suggestions = combinedSuggestions.take(6).toList();
        _isLoadingSuggestions = false;
      });

      print('Total suggestions count: ${_suggestions.length}');
    } catch (e) {
      print('Error fetching suggestions: $e');
      // Fallback to local suggestions only
      setState(() {
        _suggestions = _getLocalMatches(input);
        _isLoadingSuggestions = false;
      });
    }
  }

  List<Map<String, dynamic>> _getLocalMatches(String input) {
    final inputLower = input.toLowerCase();
    return _localLocations
        .where(
          (location) => location['name'].toLowerCase().contains(inputLower),
        )
        .map(
          (location) => {
            'display_name': '${location['name']}, Dhaka, Bangladesh',
            'main_text': location['name'],
            'secondary_text': 'Dhaka, Bangladesh',
            'lat': location['lat'],
            'lon': location['lon'],
            'type': location['type'],
            'class': 'place',
            'address': {},
            'source': 'local',
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchFromPhotonAPI(String input) async {
    try {
      // Photon API - free OpenStreetMap-based geocoding
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(input)}&limit=4&lon=90.4125&lat=23.8103&zoom=10',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'NeighborlyApp/1.0 (Flutter community app)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List? ?? [];

        return features.map<Map<String, dynamic>>((feature) {
          final properties = feature['properties'] as Map<String, dynamic>;
          final geometry = feature['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List;

          final name = properties['name'] ?? properties['street'] ?? '';
          final city =
              properties['city'] ?? properties['county'] ?? 'Bangladesh';
          final state = properties['state'] ?? 'Bangladesh';

          return {
            'display_name': '$name, $city, $state',
            'main_text': name,
            'secondary_text': '$city, $state',
            'lat': coordinates[1],
            'lon': coordinates[0],
            'type': properties['osm_value'] ?? 'place',
            'class': properties['osm_key'] ?? 'place',
            'address': properties,
            'source': 'photon',
          };
        }).toList();
      }
    } catch (e) {
      print('Photon API error: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchFromLocationIQ(String input) async {
    try {
      // LocationIQ free tier - 5000 requests per day
      final url = Uri.parse(
        'https://us1.locationiq.com/v1/search.php?key=pk.a4ac26e5c7b2b7e34ce1a55f1b8c6c5e&q=${Uri.encodeComponent(input)}&format=json&countrycodes=bd&limit=3',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'NeighborlyApp/1.0 (Flutter community app)',
          'Referer': 'https://neighborly.app',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.map<Map<String, dynamic>>((place) {
          final displayName = place['display_name'] as String;
          final lat = double.tryParse(place['lat'] as String) ?? 0.0;
          final lon = double.tryParse(place['lon'] as String) ?? 0.0;

          final parts = displayName.split(', ');
          final mainText = parts.isNotEmpty ? parts[0] : displayName;
          final secondaryText =
              parts.length > 1
                  ? parts
                      .sublist(1, parts.length > 3 ? 3 : parts.length)
                      .join(', ')
                  : '';

          return {
            'display_name': displayName,
            'main_text': mainText,
            'secondary_text': secondaryText,
            'lat': lat,
            'lon': lon,
            'type': place['type'] ?? 'place',
            'class': place['class'] ?? 'place',
            'address': {},
            'source': 'locationiq',
          };
        }).toList();
      }
    } catch (e) {
      print('LocationIQ API error: $e');
    }
    return [];
  }

  @override
  void dispose() {
    // Cancel the debounce timer when disposing
    _debounce?.cancel();
    _descriptionController.dispose();
    _timeController.dispose();
    _usernameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Color(0xFFFAF4E8),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Handle bar and header
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Color(0xFF71BB7B).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFF71BB7B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.volunteer_activism,
                        color: Color(0xFF71BB7B),
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Create Help Request",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            "Let your neighbors know how they can help",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 32,
            thickness: 1,
            color: Color(0xFF71BB7B).withOpacity(0.2),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Section
                  _buildSectionHeader("Your Information", Icons.person),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF71BB7B).withOpacity(0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF71BB7B).withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFF71BB7B),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                              'assets/images/dummy.png',
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildStyledTextField(
                                controller: _usernameController,
                                label: "Your Name",
                                icon: Icons.person_outline,
                              ),
                              SizedBox(height: 16),
                              _buildAddressField(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Request Details Section
                  _buildSectionHeader("Request Details", Icons.info_outline),
                  SizedBox(height: 16),

                  // Urgency and Help Type in a column for better responsiveness
                  Column(
                    children: [
                      _buildStyledDropdown(
                        value: _urgency,
                        items: _urgencies,
                        label: "Urgency Level",
                        icon: Icons.priority_high,
                        onChanged: (val) => setState(() => _urgency = val!),
                        getColor: _getUrgencyColor,
                      ),
                      SizedBox(height: 16),
                      _buildStyledDropdown(
                        value: _helpType,
                        items: _helpTypes,
                        label: "Help Category",
                        icon: Icons.category_outlined,
                        onChanged: (val) => setState(() => _helpType = val!),
                        getColor: _getHelpTypeColor,
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  _buildStyledTextField(
                    controller: _timeController,
                    label: "When do you need help?",
                    icon: Icons.schedule,
                    hint: "e.g., Today at 5 PM, Tomorrow morning",
                  ),

                  SizedBox(height: 20),

                  _buildStyledTextField(
                    controller: _descriptionController,
                    label: "Describe your request",
                    icon: Icons.description_outlined,
                    hint:
                        "Provide more details about what kind of help you need...",
                    maxLines: 4,
                  ),

                  SizedBox(height: 24),

                  // Image Attachment Section
                  _buildSectionHeader(
                    "Attachment (Optional)",
                    Icons.image_outlined,
                  ),
                  SizedBox(height: 16),

                  _buildImageSection(),

                  SizedBox(height: 32),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF71BB7B), Color(0xFF5EA968)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF71BB7B).withOpacity(0.3),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Submit Help Request",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Help text
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF71BB7B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF71BB7B).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF71BB7B),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your request will be visible to nearby neighbors who can offer help.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF71BB7B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF71BB7B), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF71BB7B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF71BB7B).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Color(0xFF71BB7B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF71BB7B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF71BB7B).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _addressController,
            onChanged: _onAddressChanged,
            decoration: InputDecoration(
              labelText: "Your Address",
              hintText: "Enter your location",
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF71BB7B)),
              suffixIcon:
                  _isLoadingSuggestions
                      ? Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF71BB7B),
                            ),
                          ),
                        ),
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              labelStyle: TextStyle(color: Colors.grey.shade600),
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
          ),
          if (_suggestions.isNotEmpty) _buildSuggestionsList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF71BB7B).withOpacity(0.2)),
        ),
      ),
      constraints: BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        separatorBuilder:
            (context, index) =>
                Divider(height: 1, color: Color(0xFF71BB7B).withOpacity(0.1)),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final mainText = suggestion['main_text'] as String;
          final secondaryText = suggestion['secondary_text'] as String;
          final placeType = suggestion['type'] as String? ?? 'place';
          final placeClass = suggestion['class'] as String? ?? 'place';
          final source = suggestion['source'] as String? ?? 'unknown';

          // Determine icon based on place type and class
          IconData icon = Icons.location_on;
          Color iconColor = Color(0xFF71BB7B);

          if (source == 'local') {
            iconColor = Color(0xFF71BB7B);
            if (placeType == 'city') {
              icon = Icons.location_city;
            } else if (placeType == 'area') {
              icon = Icons.home_work;
            }
          } else {
            iconColor = Colors.blue.shade600;
            if (placeClass == 'amenity') {
              if (placeType == 'hospital' || placeType == 'clinic') {
                icon = Icons.local_hospital;
              } else if (placeType == 'restaurant' || placeType == 'cafe') {
                icon = Icons.restaurant;
              } else if (placeType == 'school' || placeType == 'university') {
                icon = Icons.school;
              } else {
                icon = Icons.business;
              }
            } else if (placeClass == 'highway' || placeType == 'road') {
              icon = Icons.directions;
            } else if (placeClass == 'place') {
              if (placeType == 'city' ||
                  placeType == 'town' ||
                  placeType == 'village') {
                icon = Icons.location_city;
              } else if (placeType == 'suburb' ||
                  placeType == 'neighbourhood') {
                icon = Icons.home_work;
              }
            } else if (placeClass == 'building') {
              icon = Icons.business;
            }
          }

          return ListTile(
            dense: true,
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    mainText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (source == 'local')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFF71BB7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Nearby',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF71BB7B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle:
                secondaryText.isNotEmpty
                    ? Text(
                      secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                    : null,
            onTap: () {
              final suggestion = _suggestions[index];
              _addressController.text = suggestion['display_name'];

              // Set the selected location coordinates
              _selectedLocation = LatLng(
                (suggestion['lat'] as num).toDouble(),
                (suggestion['lon'] as num).toDouble(),
              );

              print('Selected location: $_selectedLocation');
              print('Selected address: ${suggestion['display_name']}');
              print('Source: ${suggestion['source']}');

              setState(() => _suggestions.clear());
            },
          );
        },
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    Color Function(String)? getColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF71BB7B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF71BB7B).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF71BB7B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey.shade600),
        ),
        items:
            items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Row(
                  children: [
                    if (getColor != null)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getColor(item),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        margin: EdgeInsets.only(right: 8),
                      ),
                    Expanded(
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
        style: TextStyle(color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _image != null
                  ? Color(0xFF71BB7B)
                  : Color(0xFF71BB7B).withOpacity(0.3),
          style: BorderStyle.solid,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF71BB7B).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_image == null) ...[
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Color(0xFF71BB7B).withOpacity(0.6),
            ),
            SizedBox(height: 12),
            Text(
              "Add a photo to help others understand your request",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71BB7B).withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt, size: 20),
              label: Text("Choose Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF71BB7B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  kIsWeb
                      ? Image.network(
                        _image!.path,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Image.file(
                        _image!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.edit, size: 18),
                  label: Text("Change"),
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF71BB7B),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _image = null),
                  icon: Icon(Icons.delete, size: 18),
                  label: Text("Remove"),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Emergency':
        return Colors.red;
      case 'Urgent':
        return Colors.orange;
      case 'General':
        return Color(0xFF71BB7B);
      default:
        return Colors.grey;
    }
  }

  Color _getHelpTypeColor(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Colors.red.shade400;
      case 'Fire':
        return Colors.deepOrange;
      case 'Shifting House':
        return Colors.blue;
      case 'Grocery':
        return Colors.green;
      case 'Traffic Update':
        return Colors.amber;
      case 'Route':
        return Colors.purple;
      case 'Shifting Furniture':
        return Colors.teal;
      case 'Lost Person':
        return Colors.deepPurple;
      case 'Lost Item/Pet':
        return Colors.brown;
      default:
        return Color(0xFF71BB7B);
    }
  }
}
