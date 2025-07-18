import 'package:custom_check_box/custom_check_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neighborly/app_routes.dart';

class SigninPage extends ConsumerStatefulWidget {
  final String title;
  const SigninPage({super.key, required this.title});
  @override
  ConsumerState<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<SigninPage> {
  bool _obsecure = true;
  bool _rememberMe = false;

  void onTapSignin(BuildContext context) {
    ref.read(signedInProvider.notifier).state = true;
    context.go('/mapHomePage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(left: 20.0, right: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sign in your Account",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 30.0,
                  ),
                ),
                SizedBox(height: 40.0),
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Email",
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFF71BB7B),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 25.0),
                TextField(
                  obscureText: _obsecure,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Password",
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Color(0xFF71BB7B),
                        width: 2.0,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obsecure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obsecure = !_obsecure),
                    ),
                  ),
                ),
                SizedBox(height: 5.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          // color: _rememberMe ? Colors.green : Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child:
                            _rememberMe
                                ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF71BB7B),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  ),
                                )
                                : null,
                      ),
                    ),
                    Text(
                      "Forget Password?",
                      style: TextStyle(
                        color: Color(0xFF71BB7B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 25.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF71BB7B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 50.0,
                        vertical: 15.0,
                      ),
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
                RichText(
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
                                context.push('/signup');
                              },
                      ),
                    ],
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
                    FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.red,
                      size: 40,
                    ),
                    SizedBox(width: 30.0),
                    FaIcon(
                      FontAwesomeIcons.facebook,
                      color: Colors.blue,
                      size: 40,
                    ),
                    SizedBox(width: 30.0),
                    FaIcon(
                      FontAwesomeIcons.xTwitter,
                      color: Colors.black,
                      size: 40,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
