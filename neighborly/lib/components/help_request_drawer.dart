import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
  ];

  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounce;
  LatLng? _selectedLocation;

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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchAddressSuggestions(input);
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

    // Use Google Places API for better, more specific suggestions
    const apiKey = 'AIzaSyCpv9DcJoy-AzOCxZRj0IjOfIVaF428TpQ';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$apiKey&components=country:bd&language=en&types=address|establishment|geocode',
    );

    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['predictions'] != null) {
          final predictions = data['predictions'] as List;
          print('Predictions: $predictions');

          setState(() {
            _suggestions =
                predictions
                    .map(
                      (prediction) => {
                        'description': prediction['description'] as String,
                        'place_id': prediction['place_id'] as String,
                        'structured_formatting':
                            prediction['structured_formatting'] ?? {},
                        'types': prediction['types'] as List? ?? [],
                      },
                    )
                    .toList();
            _isLoadingSuggestions = false;
          });

          print('Suggestions count: ${_suggestions.length}');
        } else {
          print(
            'API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}',
          );
          setState(() {
            _suggestions = [];
            _isLoadingSuggestions = false;
          });
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('Exception: $e');
      setState(() {
        _suggestions = [];
        _isLoadingSuggestions = false;
      });
    }
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

                  // Urgency and Help Type in a row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStyledDropdown(
                          value: _urgency,
                          items: _urgencies,
                          label: "Urgency Level",
                          icon: Icons.priority_high,
                          onChanged: (val) => setState(() => _urgency = val!),
                          getColor: _getUrgencyColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStyledDropdown(
                          value: _helpType,
                          items: _helpTypes,
                          label: "Help Category",
                          icon: Icons.category_outlined,
                          onChanged: (val) => setState(() => _helpType = val!),
                          getColor: _getHelpTypeColor,
                        ),
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
          final structuredFormatting =
              suggestion['structured_formatting'] as Map<String, dynamic>?;
          final types = suggestion['types'] as List?;

          final mainText = structuredFormatting?['main_text'] as String?;
          final secondaryText =
              structuredFormatting?['secondary_text'] as String?;

          IconData icon = Icons.location_on;
          if (types != null) {
            if (types.contains('establishment')) {
              icon = Icons.business;
            } else if (types.contains('route')) {
              icon = Icons.directions;
            } else if (types.contains('locality')) {
              icon = Icons.location_city;
            }
          }

          return ListTile(
            dense: true,
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF71BB7B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Color(0xFF71BB7B)),
            ),
            title: Text(
              mainText ?? suggestion['description'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                secondaryText != null
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
            onTap: () async {
              final suggestion = _suggestions[index];
              _addressController.text = suggestion['description'];

              try {
                const apiKey = 'AIzaSyClR4i3ETmbnVmnzFgLluRVYmiRwTa9JUU';
                final placeId = suggestion['place_id'];
                final detailsUrl = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey',
                );

                final detailsResponse = await http.get(detailsUrl);

                if (detailsResponse.statusCode == 200) {
                  final detailsData = json.decode(detailsResponse.body);

                  if (detailsData['status'] == 'OK') {
                    final geometry =
                        detailsData['result']['geometry']['location'];
                    _selectedLocation = LatLng(
                      geometry['lat'],
                      geometry['lng'],
                    );
                  }
                }
              } catch (e) {
                print('Error getting place details: $e');
              }

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
                    Text(item),
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
      default:
        return Color(0xFF71BB7B);
    }
  }
}
