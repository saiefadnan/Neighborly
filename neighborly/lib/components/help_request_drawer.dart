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
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Help Request",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/images/dummy.png'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: "Your Name",
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            onChanged: _onAddressChanged,
                            decoration: InputDecoration(
                              labelText: "Your Address",
                              suffixIcon:
                                  _isLoadingSuggestions
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          if (_suggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  final structuredFormatting =
                                      suggestion['structured_formatting']
                                          as Map<String, dynamic>?;
                                  final types = suggestion['types'] as List?;

                                  // Extract main text and secondary text
                                  final mainText =
                                      structuredFormatting?['main_text']
                                          as String?;
                                  final secondaryText =
                                      structuredFormatting?['secondary_text']
                                          as String?;

                                  // Determine icon based on place types
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
                                    leading: Icon(
                                      icon,
                                      size: 18,
                                      color: Colors.grey.shade600,
                                    ),
                                    title: Text(
                                      mainText ?? suggestion['description'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
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
                                      _addressController.text =
                                          suggestion['description'];

                                      // Get exact coordinates from Google Places Details API
                                      try {
                                        const apiKey =
                                            'AIzaSyClR4i3ETmbnVmnzFgLluRVYmiRwTa9JUU';
                                        final placeId = suggestion['place_id'];
                                        final detailsUrl = Uri.parse(
                                          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey',
                                        );

                                        final detailsResponse = await http.get(
                                          detailsUrl,
                                        );
                                        print(
                                          'Details response: ${detailsResponse.body}',
                                        );

                                        if (detailsResponse.statusCode == 200) {
                                          final detailsData = json.decode(
                                            detailsResponse.body,
                                          );

                                          if (detailsData['status'] == 'OK') {
                                            final geometry =
                                                detailsData['result']['geometry']['location'];
                                            _selectedLocation = LatLng(
                                              geometry['lat'],
                                              geometry['lng'],
                                            );
                                            print(
                                              'Selected location: $_selectedLocation',
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        print(
                                          'Error getting place details: $e',
                                        );
                                      }

                                      setState(() => _suggestions.clear());
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _urgency,
                  items:
                      _urgencies
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _urgency = val!),
                  decoration: const InputDecoration(labelText: 'Urgency'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _helpType,
                  items:
                      _helpTypes
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _helpType = val!),
                  decoration: const InputDecoration(labelText: 'Help Type'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    labelText: "Time (e.g. Today at 5 PM)",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text("Attach Image"),
                      onPressed: _pickImage,
                    ),
                    const SizedBox(width: 10),
                    if (_image != null)
                      kIsWeb
                          ? Image.network(
                            _image!.path,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          )
                          : Image.file(
                            _image!,
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _submitRequest();
                      _descriptionController.clear();
                      _timeController.clear();
                      _addressController.clear();
                      _image = null;
                      setState(() {});
                    },
                    child: const Text("Submit Request"),
                  ),
                ),
                const SizedBox(height: 10),
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
    );
  }
}
