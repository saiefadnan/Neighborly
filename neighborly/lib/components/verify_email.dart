import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyEmail extends ConsumerStatefulWidget {
  final String title;
  const VerifyEmail({super.key, required this.title});
  @override
  ConsumerState<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends ConsumerState<VerifyEmail> {
  void onTapVerify() {
    ref.read(pageNumberProvider.notifier).state = 4;
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
              Icons.mark_email_read_outlined,
              color: Colors.black,
              size: 45.0,
            ),
            Text(
              "Check your email",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 28.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 30.0),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
            children: [
              TextSpan(text: 'We sent a reset link to '),
              TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                text: 'contact@gmail.com',
              ),
              TextSpan(
                style: TextStyle(color: Colors.grey.shade700),
                text: '. Enter\n',
              ),
              TextSpan(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                text: '5 digit ',
              ),
              TextSpan(
                style: TextStyle(color: Colors.grey.shade700),
                text: 'code that is mentioned in the email.',
              ),
            ],
          ),
        ),
        SizedBox(height: 20.0),
        // PinCodeTextField(
        //   appContext: context,
        //   length: 5,
        //   autoFocus: true,
        //   onChanged: (value) {},
        //   pinTheme: PinTheme(
        //     shape: PinCodeFieldShape.box,
        //     borderRadius: BorderRadius.circular(8.0),
        //     selectedColor: Color(0xFF71BB7B),
        //     activeColor: Colors.grey,
        //     inactiveColor: Colors.red,
        //   ),
        // ),
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
            onPressed: () => onTapVerify(),
            child: Text(
              "Verify Email",
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
