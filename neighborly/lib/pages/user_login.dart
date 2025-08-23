import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'admin.dart';
class SigninForm extends StatefulWidget {
  final String title;
  const SigninForm({super.key, required this.title});

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool rememberMe = true;

  Future<void> onTapSignin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields must be filled!')),
      );
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid email or password!')),
        );
        return;
      }

      final userData = query.docs.first.data();
      if (userData['blocked'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your account is blocked. Please contact admin.')),
        );
        return;
      }

      // Credentials valid and not blocked, navigate to HomePage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage(title: 'Neighborly')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() => _isEmailFocused = _emailFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
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

  Widget buildSignInForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminHomePage()), // Replace with your admin page widget
            );
          },
        ),
        title: Text(widget.title),
        backgroundColor: const Color(0xFF71BB7B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
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
              margin: const EdgeInsets.only(top: 8.0, bottom: 40.0),
              decoration: BoxDecoration(
                color: const Color(0xFF71BB7B),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),

            // Email Field
            Text(
              "Email",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(
                hintText: "Enter your email",
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: _isEmailFocused ? const Color(0xFF71BB7B) : Colors.grey,
                  size: 20.0,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Password Field
            Text(
              "Password",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter your password",
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color:
                      _isPasswordFocused ? const Color(0xFF71BB7B) : Colors.grey,
                  size: 20.0,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: _obscurePassword ? Colors.grey : const Color(0xFF71BB7B),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Remember Me + Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => rememberMe = !rememberMe),
                  child: Row(
                    children: [
                      Container(
                        width: 18.0,
                        height: 18.0,
                        decoration: BoxDecoration(
                          color: rememberMe ? const Color(0xFF71BB7B) : Colors.transparent,
                          border: Border.all(color: const Color(0xFF71BB7B), width: 2.0),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: rememberMe
                            ? const Icon(Icons.check, color: Colors.white, size: 12.0)
                            : null,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        "Remember Me",
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
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
            const SizedBox(height: 40.0),

            // Login Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: onTapSignin,
                child: const Text(
                  "Sign in",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Divider
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade400,
                    thickness: 1.5,
                    indent: 25.0,
                    endIndent: 25.0,
                  ),
                ),
                const Text("or"),
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
            const SizedBox(height: 20.0),

            // Social Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                FaIcon(FontAwesomeIcons.google, color: Color(0xFF71BB7B), size: 30),
                SizedBox(width: 30.0),
                FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF71BB7B), size: 30),
                SizedBox(width: 30.0),
                FaIcon(FontAwesomeIcons.xTwitter, color: Color(0xFF71BB7B), size: 30),
              ],
            ),
            const SizedBox(height: 20.0),

            // Sign up text
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Don't have an Account ? ",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16.0,
                  ),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: const TextStyle(
                        color: Color(0xFF71BB7B),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildSignInForm(context);
  }
}
