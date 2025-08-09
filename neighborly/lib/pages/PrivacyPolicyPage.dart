import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        foregroundColor: Colors.black,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
        child: ListView(
          children: [
            // 1. Types of Data We Collect
            Text(
              "1. Types of Data We Collect",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "• Location Data: To provide real-time location-based help requests, alerts, and notifications, we collect your device's location information. You can manage this data by adjusting your device settings.\n\n"
              "• Profile Information: We collect your name, email address, phone number, and profile picture. This information helps build trust within the community and personalize your experience.\n\n"
              "• Help Requests & Responses: We store the details of the help requests you make, including type, location, and timestamps, along with any replies or status updates from others.\n\n"
              "• Device & Usage Information: To improve the app’s performance, we collect device-related data (e.g., device type, OS version) and usage statistics (e.g., crash reports, app interactions). This information helps us optimize the app for better user experience.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 16),

            // 2. Use of Your Personal Data
            Text(
              "2. Use of Your Personal Data",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "We use your data for the following purposes:\n"
              "• To display and match help requests with users nearby.\n"
              "• To send timely alerts, notifications, and status updates.\n"
              "• To enhance your experience and improve app performance.\n"
              "• To establish trustworthiness within the community via trust badges and user rankings.\n\n"
              "We do not use your data for any advertising or marketing purposes, nor do we share your data with third-party marketers.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 16),

            // 3. Disclosure of Your Personal Data
            Text(
              "3. Disclosure of Your Personal Data",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "We are committed to protecting your privacy. We do not sell, rent, or trade your personal information. However, we may disclose limited data to the following parties under certain circumstances:\n"
              "• Other Users: Your username, location, and help request details may be shared with other users to facilitate help offers and responses.\n"
              "• Legal Authorities: We may disclose your information if required by law or legal process (e.g., to comply with subpoenas or court orders).\n"
              "• Analytics Services: We use third-party analytics providers to help us understand how the app is used. Any shared data will be anonymized.\n\n"
              "You have the right to request deletion of your account and personal data at any time by contacting our support team.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Data Security
            Text(
              "4. Data Security",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "We use industry-standard encryption and security measures to protect your personal information and prevent unauthorized access. However, no data transmission or storage system is completely secure. We encourage you to contact us immediately if you notice any suspicious activity or potential security breaches.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 16),

            // 5. Your Rights and Control Over Data
            Text(
              "5. Your Rights and Control Over Data",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You have the following rights regarding your personal data:\n"
              "• Access: You can request a copy of your data and review the information we have collected.\n"
              "• Correction: You can update or correct any inaccurate or incomplete data.\n"
              "• Deletion: You can request to delete your account and associated data by contacting our support team.\n\n"
              "Please note that certain features of the app may be affected if you request to delete specific data.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 16),

            // 6. Contact Us
            Text(
              "6. Contact Us",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "If you have any questions, concerns, or requests regarding this Privacy Policy, please contact us at:\n\n"
              "📧 support@neighborlyapp.com\n\n"
              "We are committed to responding to all inquiries as quickly as possible and addressing your concerns.",
              style: TextStyle(
                fontSize: 15.5,
                height: 1.7,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
