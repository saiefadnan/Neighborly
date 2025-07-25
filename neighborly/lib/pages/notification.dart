import 'package:flutter/material.dart';

// 🔽 Reusable NotificationCard Widget
class NotificationCard extends StatelessWidget {
  final String name;
  final String message;
  final String image;
  final VoidCallback? onPressed;

  const NotificationCard({
    super.key,
    required this.name,
    required this.message,
    required this.image,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF71BB7B)),
      child: Row(
        children: [
          Image.asset(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onPressed ?? () {},
                  child: const Text("Go to Page"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.title});
  final String title;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<String> names = [
    "Jack Conniler",
    "Sual Canal",
    "Samuel Badre",
    "Jack Conniler",
    "Sual Canal",
    "Samuel Badre",
    "Alice Johnson",
    "Bob Smith",
    "Charlie Davis",
    "Dana White",
  ];

  final List<String> messages = [
    "Wants Grocery",
    "Wants Emergency Ambulance Service",
    "Wants Grocery",
    "Gave a traffic update",
    "Has lost his pet cat named Sania",
    "Wants Grocery",
    "Wants Grocery",
    "Gave a traffic update",
    "Wants Emergency Ambulance Service",
    "Wants Grocery",
  ];

  final List<String> images = [
    'assets/images/Image1.jpg',
    'assets/images/Image2.jpg',
    'assets/images/Image3.jpg',
    'assets/images/Image1.jpg',
    'assets/images/Image2.jpg',
    'assets/images/Image3.jpg',
    'assets/images/Image3.jpg',
    'assets/images/Image1.jpg',
    'assets/images/Image2.jpg',
    'assets/images/Image3.jpg',
  ];

  @override
  
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const Icon(Icons.notifications, color: Color.fromARGB(255, 247, 247, 247), size: 28),
          const SizedBox(width: 10),
          Text(
            widget.title,
            style: const TextStyle(
              color: Color.fromARGB(255, 250, 253, 250),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF71BB7B),
      foregroundColor: const Color.fromARGB(255, 128, 239, 132),
    ),
    body: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: names.length,
      itemBuilder: (context, index) {
        return NotificationCard(
          name: names[index],
          message: messages[index],
          image: images[index],
          onPressed: () {
            // You can handle navigation or other logic here when button is pressed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Clicked notification from ${names[index]}')),
            );
          },
        );
      },
    ),
  );
}
}