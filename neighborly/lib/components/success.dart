import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';

class Success extends ConsumerStatefulWidget {
  final String title;
  const Success({super.key, required this.title});

  @override
  ConsumerState<Success> createState() => _SuccessState();
}

class _SuccessState extends ConsumerState<Success> {
  void navigateToSignin() {
    // Navigate to the Signin page
    ref.read(pageNumberProvider.notifier).state = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
          "Congratulations! Your password has been changed. Click continue to sign in.",
          style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
        ),
        SizedBox(height: 20.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF71BB7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
              elevation: 3,
            ),
            onPressed: () => navigateToSignin(),
            child: Text(
              "Continue",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
