import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 20),

            // Achievement List
            _buildAchievementItem(
              title: "Earned Gold Certified due to successful help",
              subtitle: "May 1, 2022",
              image: 'assets/images/Medallions.png',
            ),
            _buildAchievementItem(
              title: "UserA accepted your help",
              subtitle: "May 1, 2022",
              image: 'assets/images/PostTestComplete.png',
            ),
            _buildAchievementItem(
              title: "Earned Bronze in",
              subtitle: "May 1, 2022",
              image: 'assets/images/BronzeMedal.png',
            ),
            _buildAchievementItem(
              title: "Earned Silver in",
              subtitle: "May 1, 2022",
              image: 'assets/images/SilverMedal.png',
            ),
            _buildAchievementItem(
              title: "Earned Gold in ",
              subtitle: "May 1, 2022",
              image: 'assets/images/GoldMedal.png',
            ),
            _buildAchievementItem(
              title: "Earned Gold in ",
              subtitle: "May 1, 2022",
              image: 'assets/images/GoldMedal.png',
            ),
            _buildAchievementItem(
              title: "Post successfully made in community",
              subtitle: "May 1, 2022",
              image: 'assets/images/PostTestComplete.png',
            ),
            _buildAchievementItem(
              title: "Completed Pre-Test in Customer Experience 101",
              subtitle: "May 1, 2022",
              image: 'assets/images/PostTestComplete.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required String subtitle,
    required String image,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            child: Image.asset(image, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
