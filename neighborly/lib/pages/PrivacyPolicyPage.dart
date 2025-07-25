import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
        child: ListView(
          children: const [
            // 1. Types of data we collect
            Text(
              "1. Types of data we collect",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              "• Location Data: We collect your real-time location to show nearby help requests and alerts. You control this via device settings.\n\n"
              "• Profile Info: Includes your name, phone/email, and profile picture. This helps build trust within the community.\n\n"
              "• Help Requests & Responses: We store the type, location, and time of your posts along with replies and status updates.\n\n"
              "• Device & Usage Info: We collect basic usage stats, crash reports, and device info to improve app performance.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 16),

            // 2. Use of your personal data
            Text(
              "2. Use of your personal data",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              "We use your data to:\n"
              "• Show and match help requests near you\n"
              "• Send alerts, notifications, and updates\n"
              "• Improve app experience and performance\n"
              "• Build trust badges and your helper status\n\n"
              "We do not use your data for advertising or third-party marketing.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 16),

            // 3. Disclosure of your personal data
            Text(
              "3. Disclosure of your personal data",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              "We do NOT sell your data.\n\n"
              "We may share limited data:\n"
              "• With other users (e.g., username and location when posting help)\n"
              "• With legal authorities if required\n"
              "• With analytics services (anonymized only)\n\n"
              "You may delete your account and data at any time by contacting support.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 16),

            // 4. Data Security
            Text(
              "4. Data Security",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              "We use industry-standard security to protect your data. However, no system is 100% secure. Please contact us if you notice any issues or suspicious activity.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            SizedBox(height: 16),

            // 5. Contact Us
            Text(
              "5. Contact Us",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              "If you have questions or requests about this Privacy Policy, contact us at:\n\n"
              "📧 support@neighborlyapp.com",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
