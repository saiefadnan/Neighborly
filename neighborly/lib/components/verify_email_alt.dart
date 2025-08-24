import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:neighborly/components/forget_pass.dart';
import 'package:neighborly/pages/authPage.dart';

class VerifyEmailAlt extends ConsumerStatefulWidget {
  final String title;
  const VerifyEmailAlt({super.key, required this.title});
  @override
  ConsumerState<VerifyEmailAlt> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends ConsumerState<VerifyEmailAlt> {
  String currentText = "";

  void onTapContinue() {
    ref.read(pageNumberProvider.notifier).state = 0;
  }

  Future<void> onTapResendEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Email sent!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Unexpected error occured!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(emailProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 40.0),

        // Title
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Check Your Email!",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                width: 140.0,
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
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: 'We sent a reset link to '),
              TextSpan(
                text: email,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15.0),

        // PIN Code Input
        // PinCodeTextField(
        //   appContext: context,
        //   length: 5,
        //   autoFocus: true,
        //   onChanged: (value) {
        //     setState(() {
        //       currentText = value;
        //     });
        //   },
        //   pinTheme: PinTheme(
        //     shape: PinCodeFieldShape.box,
        //     borderRadius: BorderRadius.circular(8.0),
        //     fieldHeight: 56.0,
        //     fieldWidth: 56.0,
        //     activeFillColor: Colors.white,
        //     inactiveFillColor: Colors.white,
        //     selectedFillColor: Colors.white,
        //     activeColor: Color(0xFF71BB7B),
        //     inactiveColor: Colors.grey.shade300,
        //     selectedColor: Color(0xFF71BB7B),
        //     borderWidth: 2.0,
        //   ),
        //   enableActiveFill: true,
        //   textStyle: TextStyle(
        //     fontSize: 20.0,
        //     fontWeight: FontWeight.w600,
        //     color: Color(0xFF71BB7B),
        //   ),
        //   animationType: AnimationType.fade,
        //   animationDuration: Duration(milliseconds: 300),
        // ),
        // SizedBox(height: 40.0),

        // // Verify Code Button
        SizedBox(
          width: double.infinity,
          child: Lottie.asset(
            'assets/images/reset_password.json', // Path to your animation file
            width: 200.0,
            height: 200.0,
            fit: BoxFit.contain,
          ),
        ),

        SizedBox(height: 15.0),

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
            onPressed: () => onTapContinue(),
            child: Text(
              "Continue",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
        // Haven't got email text
        SizedBox(height: 15.0),
        Center(
          child: RichText(
            text: TextSpan(
              text: "Haven't got the email yet? ",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
              ),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => onTapResendEmail(email),
                    child: Text(
                      "Resend email",
                      style: TextStyle(
                        color: Color(0xFF71BB7B),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF71BB7B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
