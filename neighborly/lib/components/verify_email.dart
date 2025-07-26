import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyEmail extends ConsumerStatefulWidget {
  final String title;
  const VerifyEmail({super.key, required this.title});
  @override
  ConsumerState<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends ConsumerState<VerifyEmail> {
  String currentText = "";

  void onTapVerify() {
    ref.read(pageNumberProvider.notifier).state = 4;
  }

  void onTapResendEmail() {
    // Handle resend email logic here
  }

  @override
  Widget build(BuildContext context) {
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
                text: 'contact@gmail.com',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextSpan(text: '.\nEnter '),
              TextSpan(
                text: '5 digit ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              TextSpan(text: 'code that is mentioned in the email.'),
            ],
          ),
        ),
        SizedBox(height: 40.0),

        // PIN Code Input
        PinCodeTextField(
          appContext: context,
          length: 5,
          autoFocus: true,
          onChanged: (value) {
            setState(() {
              currentText = value;
            });
          },
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8.0),
            fieldHeight: 56.0,
            fieldWidth: 56.0,
            activeFillColor: Colors.white,
            inactiveFillColor: Colors.white,
            selectedFillColor: Colors.white,
            activeColor: Color(0xFF71BB7B),
            inactiveColor: Colors.grey.shade300,
            selectedColor: Color(0xFF71BB7B),
            borderWidth: 2.0,
          ),
          enableActiveFill: true,
          textStyle: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF71BB7B),
          ),
          animationType: AnimationType.fade,
          animationDuration: Duration(milliseconds: 300),
        ),
        SizedBox(height: 40.0),

        // Verify Code Button
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
            onPressed: () => onTapVerify(),
            child: Text(
              "Verify Code",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),

        SizedBox(height: 24.0),

        // Haven't got email text
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
                    onTap: onTapResendEmail,
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
