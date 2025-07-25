import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/functions/init_pageval.dart';
import 'package:neighborly/pages/authPage.dart';

class SignupForm extends ConsumerStatefulWidget {
  final String title;
  const SignupForm({super.key, required this.title});
  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  bool _obsecure = true;

  void onTapSignup(BuildContext context) {
    ref.read(signedInProvider.notifier).state = true;
    context.go('/appShell');
    initPageVal(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.black,
              size: 45.0,
            ),
            Text(
              "Create your Account",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 30.0),
        Text(
          "Username",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.grey.shade700,
          ),
        ),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hint: Text("Enter your name"),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          "Email",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.grey.shade700,
          ),
        ),
        TextField(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hint: Text("Enter your email"),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          "Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.grey.shade700,
          ),
        ),
        TextField(
          obscureText: _obsecure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hint: Text("Create your password"),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(
              Icons.lock_open_outlined,
              color: Colors.grey.shade600,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obsecure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obsecure = !_obsecure),
            ),
          ),
        ),
        SizedBox(height: 20.0),
        Text(
          "Confirm Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
            color: Colors.grey.shade700,
          ),
        ),
        TextField(
          obscureText: _obsecure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hint: Text("Confirm your password"),
            hintStyle: TextStyle(color: Colors.grey.shade600),
            prefixIcon: Icon(Icons.lock_outlined, color: Colors.grey.shade600),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            suffixIcon: IconButton(
              icon: Icon(_obsecure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obsecure = !_obsecure),
            ),
          ),
        ),
        SizedBox(height: 5.0),
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween),
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
            onPressed: () => onTapSignup(context),
            child: Text(
              "SIGN UP",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
        SizedBox(height: 30.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 1.5,
                indent: 25.0,
                endIndent: 25.0,
              ),
            ),
            Text("or"),
            Expanded(
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 1.5,
                indent: 25.0,
                endIndent: 25.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 40),
            SizedBox(width: 30.0),
            FaIcon(FontAwesomeIcons.facebook, color: Colors.blue, size: 40),
            SizedBox(width: 30.0),
            FaIcon(FontAwesomeIcons.xTwitter, color: Colors.black, size: 40),
          ],
        ),
        SizedBox(height: 40.0),
        Center(
          child: RichText(
            text: TextSpan(
              text: "Already have an account? ",
              style: TextStyle(color: Colors.grey, fontSize: 16.0),
              children: [
                TextSpan(
                  text: "Sign In",
                  style: TextStyle(
                    color: Color(0xFF71BB7B),
                    fontWeight: FontWeight.bold,
                    // decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          ref.read(pageNumberProvider.notifier).state = 0;
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
