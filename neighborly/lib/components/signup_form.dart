import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isUsernameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  void onTapSignup(BuildContext context) {
    ref.read(signedInProvider.notifier).state = true;
    context.go('/appShell');
    initPageVal(ref);
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(() {
      setState(() {
        _isUsernameFocused = _usernameFocusNode.hasFocus;
      });
    });
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
    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  "Sign up",
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
          SizedBox(height: 24.0),

          // Username Field
          Text(
            "Username",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _usernameController,
            focusNode: _usernameFocusNode,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter your username",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color:
                    _isUsernameFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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
                color:
                    _isEmailFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
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
                    _isPasswordFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
                size: 20.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color:
                      _obscurePassword
                          ? Colors.grey.shade400
                          : Color(0xFF71BB7B),
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
          SizedBox(height: 24.0),

          // Confirm Password Field
          Text(
            "Confirm Password",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              filled: false,
              hintText: "Confirm your password",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color:
                    _isConfirmPasswordFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
                size: 20.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color:
                      _obscureConfirmPassword
                          ? Colors.grey.shade400
                          : Color(0xFF71BB7B),
                  size: 20.0,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
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
          SizedBox(height: 40.0),

          // Create Account Button
          Container(
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
              onPressed: () => onTapSignup(context),
              child: Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          SizedBox(height: 30.0),

          // Already have account text
          Center(
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: "Signin",
                    style: TextStyle(
                      color: Color(0xFF71BB7B),
                      fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
