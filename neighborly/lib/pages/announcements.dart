import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitAnnouncement() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleController.text.trim().isEmpty
            ? 'Announcement'
            : _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': Timestamp.now(),
      });

      _titleController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted')),
      );
    } catch (e) {
      debugPrint('Error posting announcement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post announcement')),
      );
    }

    setState(() => _isSubmitting = false);
  }

  Widget _buildAnnouncementCard(Map<String, dynamic> data) {
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(data['title'] ?? 'Announcement',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(data['message'] ?? ''),
            const SizedBox(height: 6),
            Text(formattedDate,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Announcement message',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAnnouncement,
                  icon: const Icon(Icons.send),
                  label: const Text('Post Announcement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Previous Announcements',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No announcements yet.'));
                }

                final announcements = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    return _buildAnnouncementCard(
                      announcements[index].data() as Map<String, dynamic>,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
