import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';

final emailProvider = StateProvider<String>((ref) => '');

class ForgetPass extends ConsumerStatefulWidget {
  final String title;
  const ForgetPass({super.key, required this.title});
  @override
  ConsumerState<ForgetPass> createState() => _ForgetPassState();
}

class _ForgetPassState extends ConsumerState<ForgetPass> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  Future<void> onTapReset() async {
    try {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Please enter your email")));
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ref.read(emailProvider.notifier).state = email;
      ref.read(pageNumberProvider.notifier).state = 3;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error occured!")));
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 70.0),
        // Title
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                width: 120.0,
                height: 3.0,
                margin: EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  color: Color(0xFF71BB7B),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.0),

        // Subtitle
        Text(
          "Please enter your email to reset the password",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 40.0),

        // Email Field
        Text(
          "Your Email",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          decoration: InputDecoration(
            filled: false,
            hintText: "Enter your email",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _isEmailFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
              size: 20.0,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
        SizedBox(height: 40.0),

        // Reset Password Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF71BB7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.symmetric(vertical: 16.0),
              elevation: 0,
            ),
            onPressed: () async => await onTapReset(),
            child: Text(
              "Reset Password",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
