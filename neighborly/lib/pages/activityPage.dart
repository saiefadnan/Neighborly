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
            const Center(
              child: Text(
                "ACTIVITY",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Achievement List
            _buildAchievementItem(
              title: "Earned Gold Certification in Change Management",
              subtitle: "May 1, 2022",
              icon: Icons.star,
              iconColor: Colors.yellow,
            ),
            _buildAchievementItem(
              title: "Completed Drive-Thru",
              subtitle: "May 1, 2022",
              icon: Icons.directions_car,
              iconColor: Colors.grey,
            ),
            _buildAchievementItem(
              title: "Earned Bronze in Drive-Thru",
              subtitle: "May 1, 2022",
              icon: Icons.access_time,
              iconColor: Colors.brown,
            ),
            _buildAchievementItem(
              title: "Earned Silver in Drive-Thru",
              subtitle: "May 1, 2022",
              icon: Icons.access_time,
              iconColor: Colors.grey,
            ),
            _buildAchievementItem(
              title: "Earned Gold in Drive-Thru",
              subtitle: "May 1, 2022",
              icon: Icons.star,
              iconColor: Colors.yellow,
            ),
            _buildAchievementItem(
              title: "Earned Gold in Drive-Thru 101",
              subtitle: "May 1, 2022",
              icon: Icons.star,
              iconColor: Colors.yellow,
            ),
            _buildAchievementItem(
              title: "Completed Pre-Test in Customer Experience 101",
              subtitle: "May 1, 2022",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
            _buildAchievementItem(
              title: "Completed Pre-Test in Customer Experience 101",
              subtitle: "May 1, 2022",
              icon: Icons.check_circle,
              iconColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.2),
            child: Icon(icon, color: iconColor, size: 24),
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
