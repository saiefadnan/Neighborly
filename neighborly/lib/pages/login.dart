import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/appshell.dart';
import 'package:neighborly/main.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String title;
  const LoginPage({super.key, required this.title});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _obsecure = true;

  void onTapLogin(BuildContext context) {
    ref.read(loggedInProvider.notifier).state = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
    );
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
                  "Login",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30.0),
                ),
                SizedBox(height: 20.0),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 40.0),
                TextField(
                  obscureText: _obsecure,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obsecure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obsecure = !_obsecure),
                    ),
                  ),
                ),
                SizedBox(height: 40.0),
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
                      elevation: 5,
                    ),
                    onPressed: () => onTapLogin(context),
                    child: Text("Login", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
