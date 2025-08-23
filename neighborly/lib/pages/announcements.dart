import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}
//it will also be displayed in users page
class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _postAnnouncement() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    await FirebaseFirestore.instance.collection('announcements').add({
      'title': title,
      'message': message,
      'timestamp': Timestamp.now(),
    });

    _titleController.clear();
    _messageController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Announcement posted!')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF71BB7B),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _postAnnouncement,
                  child: const Text('Post Announcement'),
                ),
              ],
            ),
          ),
          const Divider(),
          const Expanded(child: AnnouncementsList()),
        ],
      ),
    );
  }
}

// Only shows the list of announcements, no posting UI
class AnnouncementsList extends StatelessWidget {
  const AnnouncementsList({super.key});

  Widget _buildAnnouncementCard(Map<String, dynamic> data) {
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(timestamp);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return StreamBuilder<QuerySnapshot>(
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
          shrinkWrap: true,
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(
              announcements[index].data() as Map<String, dynamic>,
            );
          },
        );
      },
    );
  }
}
//final connection done