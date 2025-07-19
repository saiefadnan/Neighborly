import 'package:flutter/material.dart';

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(image),
          radius: 24,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
        onTap: onPressed,
      ),
    );
  }
}
