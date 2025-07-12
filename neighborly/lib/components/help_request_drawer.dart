import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _addressController = TextEditingController(text: '123, Dhanmondi, Dhaka');
  String _urgency = 'Emergency';
  String _helpType = 'Medical';
  File? _image;

  final _urgencies = ['Emergency', 'Urgent', 'General'];
  final _helpTypes = [
    'Medical', 'Fire', 'Shifting House', 'Grocery',
    'Traffic Update', 'Route', 'Shifting Furniture'
  ];

  List<String> _suggestions = [];
  bool _isLoadingSuggestions = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) throw Exception("No location found");

      final LatLng coordinates = LatLng(locations.first.latitude, locations.first.longitude);

      final helpData = {
        "type": _urgency,
        "location": coordinates,
        "description": description,
        "time": time,
        "image": _image,
      };

      widget.onSubmit(helpData);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Help request submitted")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid address")),
      );
    }
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.length < 3) return;
    setState(() => _isLoadingSuggestions = true);
    final url = Uri.parse("https://nominatim.openstreetmap.org/search?q=$input&format=json&limit=5");
    final response = await http.get(url, headers: {"User-Agent": "FlutterApp"});

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      setState(() {
        _suggestions = data.map((e) => e['display_name'] as String).toList();
        _isLoadingSuggestions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Help Request", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/dummy.png')),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: "Your Name"),
                    ),
          const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        onChanged: _fetchAddressSuggestions,
                        decoration: const InputDecoration(labelText: "Your Address"),
                      ),
                      if (_suggestions.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Text(_suggestions[index]),
                            onTap: () {
                              _addressController.text = _suggestions[index];
                              setState(() => _suggestions.clear());
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
              items: _urgencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _urgency = val!),
              decoration: const InputDecoration(labelText: 'Urgency'),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _helpType,
              items: _helpTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _helpType = val!),
              decoration: const InputDecoration(labelText: 'Help Type'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: "Time (e.g. Today at 5 PM)"),
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
                      ? Image.network(_image!.path, height: 50, width: 50, fit: BoxFit.cover)
                      : Image.file(_image!, height: 50, width: 50, fit: BoxFit.cover),
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
                  Navigator.pop(context);
                },
                child: const Text("Submit Request"),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
