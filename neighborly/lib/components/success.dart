import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Success extends ConsumerStatefulWidget {
  final String title;
  const Success({super.key, required this.title});

  @override
  ConsumerState<Success> createState() => _SuccessState();
}

class _SuccessState extends ConsumerState<Success> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.black, size: 45.0),
            Text(
              "Congratulations!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
            ),
          ],
        ),
        SizedBox(height: 30.0),
        Text(
          "Your account has been successfully created.",
          style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
