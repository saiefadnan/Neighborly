import 'package:flutter/material.dart';

class AppNavigationPage extends StatelessWidget {
  const AppNavigationPage({super.key});

  void _showImageDialog(BuildContext context, String assetPath, String label) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 32.0,
                        left: 8,
                        right: 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image(
                          image: AssetImage(assetPath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'About App',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Home Page Navigation Section
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 2),
            child: Text(
              "Home Page Navigation",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "The Home page provides quick access to all major features of Neighborly. Use it to navigate to Forum, Help List, Community, Notifications, Map, Profile, Emergency Number (call 999), and the AI Chatbot.",
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap:
                  () => _showImageDialog(
                    context,
                    'assets/images/homepagess.png',
                    'Home Page',
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('assets/images/homepagess.png'),
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• Forum: Access and participate in community discussions.',
                ),
                SizedBox(height: 4),
                Text('• Help List: View and respond to help requests.'),
                SizedBox(height: 4),
                Text('• Community: Connect with your local community.'),
                SizedBox(height: 4),
                Text('• Notifications: Stay updated with important alerts.'),
                SizedBox(height: 4),
                Text('• Map: Find locations and resources nearby.'),
                SizedBox(height: 4),
                Text('• Profile: Manage your personal information.'),
                SizedBox(height: 4),
                Text('• Emergency Number: Quickly call 999 for emergencies.'),
                SizedBox(height: 4),
                Text('• AI Chatbot: Get instant help and answers.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Statistics Section
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 2),
            child: Text(
              "Statistics",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "The Statistics page provides a comprehensive overview of your activity and performance in the Neighborly community.",
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap:
                  () => _showImageDialog(
                    context,
                    'assets/images/statss.png',
                    'Statistics Page',
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('assets/images/statss.png'),
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• Helped Requests:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Shows the total number of help requests you have successfully responded to.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Leaderboard Rank:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Displays your current rank among all users in your community based on your helpfulness.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Help Response Success Rate:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Indicates the percentage of help requests you responded to that were marked as successful.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Help Range Radius:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Shows the maximum distance from your location where you have provided help.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Most Requested Help Types:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'A graph showing the most common types of help requested in your community.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contributions Section
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 2),
            child: Text(
              "Contributions",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "The Contributions page highlights the different types of help you have provided to your community.",
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap:
                  () => _showImageDialog(
                    context,
                    'assets/images/contributionss.png',
                    'Contributions Page',
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('assets/images/contributionss.png'),
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• Contribution Categories:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'See a breakdown of your help in areas like groceries, medical aid, emergencies, and more.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Visual Summary:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'A visual chart helps you understand where you have made the most impact.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Motivation:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Encourages you to diversify your support and contribute to new areas.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Achievements Section
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 2),
            child: Text(
              "Achievements",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "The Achievements page displays your user level, progress towards the next level, and the honors you have earned.",
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap:
                  () => _showImageDialog(
                    context,
                    'assets/images/achievess.png',
                    'Achievements Page',
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('assets/images/achievess.png'),
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• User Level:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Shows your current level and how much is needed to reach the next level.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Honors:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Earned for helping others, with bronze, silver, or gold balls awarded based on the severity and frequency of your contributions.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Milestones:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Track your progress: e.g., help 2/5 for bronze, 3/5 for silver, 5/5 for gold certification.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Motivation:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Encourages you to reach new milestones and celebrate your impact in the community.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Activity Section
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 2),
            child: Text(
              "Activity",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "The Activity page provides a timeline of your previous actions within the app.",
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap:
                  () => _showImageDialog(
                    context,
                    'assets/images/activityss.png',
                    'Activity Page',
                  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const Image(
                  image: AssetImage('assets/images/activityss.png'),
                  fit: BoxFit.contain,
                  height: 220,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Key Features:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '• Timeline:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Review your past help responses, honors achieved, and posts made in the community.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Post Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'See whether your community posts were successfully published.',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '• Engagement Tracking:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child: Text(
                    'Keep track of your engagement and accomplishments over time.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
