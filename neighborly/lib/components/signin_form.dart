import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/functions/init_pageval.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:http/http.dart' as http;

class SigninForm extends ConsumerStatefulWidget {
  final String title;
  const SigninForm({super.key, required this.title});
  @override
  ConsumerState<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends ConsumerState<SigninForm> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  Future<bool> fetchData() async {
    final url = Uri.parse('http://192.168.0.101:4000/api/test');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print('Message: ${data['message']}');
        return true;
      } else {
        //print('Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      //print('Caught error: $e');
      return false;
    }
  }

  void onTapSignin(BuildContext context) async {
    final success = true; //await fetchData();
    if (!context.mounted) return;
    if (success) {
      ref.read(signedInProvider.notifier).state = true;
      context.go('/appShell');
      initPageVal(ref);
    } else {
      print("Login failed. Please check your credentials.");
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
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign in",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                width: 60.0,
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
        SizedBox(height: 40.0),

        // Email Field
        Text(
          "Email",
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
        SizedBox(height: 24.0),

        // Password Field
        Text(
          "Password",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            filled: false,
            hintText: "Enter your password",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color:
                  _isPasswordFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
              size: 20.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color:
                    _obscurePassword ? Colors.grey.shade400 : Color(0xFF71BB7B),
                size: 20.0,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
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
        SizedBox(height: 16.0),

        // Remember Me and Forgot Password Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      color:
                          _rememberMe ? Color(0xFF71BB7B) : Colors.transparent,
                      border: Border.all(color: Color(0xFF71BB7B), width: 2.0),
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    child:
                        _rememberMe
                            ? Icon(Icons.check, color: Colors.white, size: 12.0)
                            : null,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    "Remember Me",
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(pageNumberProvider.notifier).state = 2,
              child: Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Color(0xFF71BB7B),
                  fontWeight: FontWeight.w500,
                  fontSize: 14.0,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 40.0),

        // Login Button
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
            onPressed: () => onTapSignin(context),
            child: Text(
              "Sign in",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.0),
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
            FaIcon(FontAwesomeIcons.google, color: Color(0xFF71BB7B), size: 30),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.facebook,
              color: Color(0xFF71BB7B),
              size: 30,
            ),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.xTwitter,
              color: Color(0xFF71BB7B),
              size: 30,
            ),
          ],
        ),
        SizedBox(height: 20.0),
        // Don't have account text
        Center(
          child: RichText(
            text: TextSpan(
              text: "Don't have an Account ? ",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: "Sign up",
                  style: TextStyle(
                    color: Color(0xFF71BB7B),
                    fontWeight: FontWeight.w600,
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
