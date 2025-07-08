import 'package:flutter/material.dart';
import 'activityPage.dart';
import 'editProfile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 24),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                child: Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Colors.blueGrey,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Mir Sayef',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const TabBar(
              labelColor: Color(0xFF5B5B7E),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF5B5B7E),
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: "STATS"),
                Tab(text: "ACHIEVEMENTS"),
                Tab(text: "ACTIVITY"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // STATS TAB
                  Center(child: Text("Stats Coming Soon")),
                  // ACHIEVEMENTS TAB
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Level Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(
                                            0xFF5B5B7E,
                                          ),
                                          child: const Text(
                                            '2',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Level 2',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 4,
                                            ), // Space between level and points text
                                            Text(
                                              '800 Points to next level',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ), // Add some space between Level and Points
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer outline
                                    Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius: BorderRadius.circular(19),
                                      ),
                                    ),
                                    // Progress bar background
                                    // Progress bar background
                                    Positioned(
                                      left:
                                          19, // half of circle diameter (38/2)
                                      right: 19,
                                      child: Container(
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2E6C3),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Progress bar foreground (Dynamic width from level 2 to 3)
                                    Positioned(
                                      left: 19,
                                      right:
                                          19 +
                                          (0.35 *
                                              312), // 65% filled, so 35% remains empty on the right
                                      child: Container(
                                        height: 28,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFFD966),
                                              Color(0xFFFFE9A7),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Left circle (level 2)
                                    Positioned(
                                      left: 0,
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD966),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Color(0xFFF2E6C3),
                                            width: 3,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '2',
                                            style: TextStyle(
                                              color: Color(0xFF5B5B7E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Right circle (level 3)
                                    Positioned(
                                      right: 0,
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3CD),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Color(0xFFF2E6C3),
                                            width: 3,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '3',
                                            style: TextStyle(
                                              color: Color(0xFFBBA86B),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Centered star and score
                                    Positioned.fill(
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              color: const Color(0xFFEECF60),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 6),
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '5200',
                                                    style: TextStyle(
                                                      color: Colors.brown[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '/6000',
                                                    style: TextStyle(
                                                      color: Colors.brown[300],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Medals Section
                          _sectionTitle('MEDALS', 53),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _medalCard(
                                'Gold',
                                24,
                                Colors.amber,
                                'assets/images/GoldMedal.png',
                              ),
                              _medalCard(
                                'Silver',
                                18,
                                Colors.blueGrey[200]!,
                                'assets/images/SilverMedal.png',
                              ),
                              _medalCard(
                                'Bronze',
                                11,
                                Colors.brown[300]!,
                                'assets/images/BronzeMedal.png',
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Certifications Section
                          _sectionTitle('CERTIFICATIONS', 8),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _certCard(
                                'Food Safety\nProtocols',
                                'Bronze Certified',
                                Colors.brown[200]!,
                              ),
                              _certCard(
                                'Facilities &\nMaintenance',
                                'Silver Certified',
                                Colors.blueGrey[200]!,
                              ),
                              _certCard(
                                'Sustainability\nPractices',
                                'Gold Certified',
                                Colors.amber[200]!,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Badges Section
                          _sectionTitle('BADGES', 0),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _badgeCard(Icons.star, 'Top Contributor'),
                              const SizedBox(width: 12),
                              _badgeCard(Icons.fireplace, 'Community Hero'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ACTIVITY TAB
                  ActivityPage(),
                  //Center(child: Text("Activity Coming Soon")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          '$title',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B5B7E),
          ),
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _medalCard(String label, int count, Color color, String imagePath) {
    return Container(
      width: 110, // card sizing
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ), //vertically resize kore
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Bottom-right shadow
          BoxShadow(
            color: const Color(
              0xFFA6ABBD,
            ).withOpacity(0.5), // light purple shadow
            blurRadius: 18.58, // Blur intensity
            offset: const Offset(2.48, 2.48), // Shadow position (bottom-right)
          ),
          // Upper-left shadow
          BoxShadow(
            color: const Color(0xFFFAFBFF), // light blue shadow
            blurRadius: 16.1, // Blur intensity
            offset: const Offset(-1.24, -1.24), // Shadow position (upper-left)
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            imagePath,
            width: 50, // Adjust the width as needed
            height: 50, // Adjust the height as needed
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Certification Card Widget
  Widget _certCard(String title, String cert, Color color) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.verified, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cert,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Badge Card Widget
  Widget _badgeCard(IconData icon, String label) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
