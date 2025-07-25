import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/functions/init_pageval.dart';
import 'package:neighborly/pages/authPage.dart';

class SigninForm extends ConsumerStatefulWidget {
  final String title;
  const SigninForm({super.key, required this.title});
  @override
  ConsumerState<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends ConsumerState<SigninForm> {
  bool _obsecure = true;
  bool _rememberMe = false;

  void onTapSignin(BuildContext context) {
    ref.read(signedInProvider.notifier).state = true;
    context.go('/appShell');
    initPageVal(ref);
  }

  @override
  Widget build(BuildContext context) {
    //final scnHeight = MediaQuery.of(context).size.height;
    // final offY = scnHeight * 0.45;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_outlined, color: Colors.black, size: 4.0),
            Text(
              "Sign in your Account",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28.0,
              ),
            ),
          ],
        ),

        SizedBox(height: 30.0),
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
            hint: Text("Enter your password"),
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
        SizedBox(height: 10.0),
        Padding(
          padding: EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.only(left: 3.0),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          // color: _rememberMe ? Colors.green : Colors.white,
                          border: Border.all(color: Color(0xFF71BB7B)),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child:
                            _rememberMe
                                ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF71BB7B),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      SizedBox(width: 10.0),
                      const Text("Remember Me"),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(pageNumberProvider.notifier).state = 2,
                child: Text(
                  "Forget Password?",
                  style: TextStyle(
                    color: Color(0xFF71BB7B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
            onPressed: () => onTapSignin(context),
            child: Text(
              "SIGN IN",
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
            FaIcon(FontAwesomeIcons.google, color: Color(0xFF71BB7B), size: 40),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.facebook,
              color: Color(0xFF71BB7B),
              size: 40,
            ),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.xTwitter,
              color: Color(0xFF71BB7B),
              size: 40,
            ),
          ],
        ),
        SizedBox(height: 20.0),
        Center(
          child: RichText(
            text: TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(color: Colors.grey, fontSize: 16.0),
              children: [
                TextSpan(
                  text: "Sign Up",
                  style: TextStyle(
                    color: Color(0xFF71BB7B),
                    fontWeight: FontWeight.bold,
                    // decoration: TextDecoration.underline,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          ref.read(pageNumberProvider.notifier).state = 1;
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
