import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  List<Map<String, String>> eventTypes = [
    {"title": "Tree Plantation", "desc": "Join a green cause."},
    {"title": "Invitation Party", "desc": "Celebrate and invite friends."},
    {"title": "Community Clean-Up", "desc": "Help clean the neighborhood."},
    {"title": "Food Drive", "desc": "Donate and distribute food."},
    {"title": "Block Party", "desc": "Fun gathering with the block."},
  ];

  Future<void> pickImage() async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(pickedImageProvider.notifier).state = image.path;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = ref.watch(selectedEventTypeProvider);
    final range = ref.watch(notificationRangeProvider);
    final imagePath = ref.watch(pickedImageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        backgroundColor: Color(0xFFF7F2E7),
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

            // Event type cards
            ...eventTypes.map(
              (event) => Card(
                color: selectedType == event["title"] ? Colors.blue[50] : null,
                child: ListTile(
                  title: Text(event["title"]!),
                  subtitle: Text(event["desc"]!),
                  trailing: ElevatedButton(
                    onPressed:
                        () =>
                            ref.read(selectedEventTypeProvider.notifier).state =
                                event["title"],
                    child: const Text("Select"),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildTextField("Event Title", titleController),
            _buildTextField("Date", dateController),
            _buildTextField("Time", timeController),
            _buildTextField("Location", locationController),

            const SizedBox(height: 12),
            const Text("Map Preview (placeholder)"),
            Container(
              height: 150,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: const Text("Google Map Placeholder"),
            ),

            const SizedBox(height: 12),
            _buildTextField("Description", descriptionController, maxLines: 3),

            const SizedBox(height: 12),
            const Text("Optional Image"),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[200],
                child:
                    imagePath != null
                        ? Image.file(File(imagePath), fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent,
                ),
                onPressed: () {
                  // You can handle event creation logic here
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
