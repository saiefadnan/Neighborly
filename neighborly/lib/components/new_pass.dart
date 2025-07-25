import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neighborly/pages/authPage.dart';

class NewPass extends ConsumerStatefulWidget {
  final String title;
  const NewPass({super.key, required this.title});
  @override
  ConsumerState<NewPass> createState() => _NewPassState();
}

class _NewPassState extends ConsumerState<NewPass> {
  bool _obsecure = true;
  void onTapUpdate() {
    ref.read(pageNumberProvider.notifier).state = 5;
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
            Icon(Icons.build_circle_outlined, color: Colors.black, size: 45.0),
            Text(
              "Reset your password",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28.0,
              ),
            ),
          ],
        ),
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
        SizedBox(height: 30.0),
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
            onPressed: () => onTapUpdate(),
            child: Text(
              "Update Password",
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
