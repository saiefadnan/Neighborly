import 'package:flutter/material.dart';
import 'NotificationCard.dart'; // Adjust path

class NotificationScreen extends StatelessWidget {
  final String title;
  const NotificationScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final List<String> names = ['John Doe', 'Jane Smith', 'Michael Johnson'];
    final List<String> messages = [
      'Hello there!',
      'How are you?',
      'Don\'t forget our meeting.'
    ];
    final List<String> images = [
      'assets/images/p1.jpg',
      'assets/images/p2.jpg',
      'assets/images/p3.jpg'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: names.length,
        itemBuilder: (context, index) {
          return NotificationCard(
            name: names[index],
            message: messages[index],
            image: images[index],
          );
        },
      ),
    );
  }
}
