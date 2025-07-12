import 'package:flutter/material.dart';

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
    "Has lost his pet cat named sania",
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
        title: Text(widget.title),
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: const Color(0xFFFAF4E8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: names.length,
          itemBuilder: (context, index) {
            return Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    images[index],
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
                          names[index],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          messages[index],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Go to Page"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
