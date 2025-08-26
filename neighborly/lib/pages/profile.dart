import 'package:flutter/material.dart';
import 'activityPage.dart';
import 'editProfile.dart';
import 'statistics.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

class _ProfileNameHeader extends StatefulWidget {
  const _ProfileNameHeader({Key? key}) : super(key: key);

  @override
  State<_ProfileNameHeader> createState() => _ProfileNameHeaderState();
}

class _ProfileNameHeaderState extends State<_ProfileNameHeader> {
  String? _name;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }
      final token = await user.getIdToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.infosApiPath}');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          _name =
              ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? ''))
                  .trim();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(
      _name ?? '',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Color(0xFF222222),
      ),
    );
  }
}

class MilestoneData {
  final String label;
  final String cert;
  final Color color;
  final IconData icon;
  final int current;
  final int total;
  //final String? lottiePath; // <-- Add this

  MilestoneData({
    required this.label,
    required this.cert,
    required this.color,
    required this.icon,
    required this.current,
    required this.total,
    //this.lottiePath, // <-- Add this
  });
}

final List<MilestoneData> milestones = [
  MilestoneData(
    label: 'Rookie Hero',
    cert: 'Bronze Certified',
    color: Colors.brown[400]!,
    icon: Icons.hourglass_bottom, // Pending icon
    current: 2,
    total: 5,
  ),
  MilestoneData(
    label: 'Silver Surfer',
    cert: 'Silver Certified',
    color: Colors.blueGrey[400]!,
    icon: Icons.hourglass_bottom, // Pending icon
    current: 3,
    total: 5,
  ),
  MilestoneData(
    label: 'Gold Guardian',
    cert: 'Gold Certified',
    color: Colors.amber[400]!,
    icon: Icons.verified, // Gold tick
    current: 5,
    total: 5,
  ),
];

class BadgeData {
  final String label;
  final String description;
  final String? lottiePath;
  final bool unlocked;

  BadgeData({
    required this.label,
    required this.description,
    this.lottiePath,
    this.unlocked = false,
  });
}

double getResponsiveCardWidth(
  BuildContext context, {
  double fraction = 0.28,
  double min = 100,
  double max = 180,
}) {
  final width = MediaQuery.of(context).size.width;
  final cardWidth = width * fraction;
  return cardWidth.clamp(min, max);
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint =
        Paint()
          ..color = color.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc with rounded ends
    final fgPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
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

            // ...existing code...
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Polygon.png',
                        width: 130,
                        height: 130,
                      ),
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: AssetImage('assets/images/dummy.png'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const _ProfileNameHeader(),
                ],
              ),
            ),
            // ...existing code...
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
                  //Center(child: Text("Stats Coming Soon")),
                  StatisticsPage(),
                  // ACHIEVEMENTS TAB
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Level Card
                          Container(
                            width:
                                MediaQuery.of(context).size.width *
                                0.92, // almost full width, responsive
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

                                    const SizedBox(height: 6),
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
                                    // Progress bar(Dynamic width from level 2 to 3)
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
                                              Color(0xFFF3B14E),
                                              Color(0xFFFFCE51),
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
                          _sectionTitle('HONORS', 53),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _medalCard(
                                  context,
                                  'Gold',
                                  24,
                                  Colors.amber,
                                  'assets/images/GoldMedal.png',
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ), // Add spacing if required
                              Expanded(
                                child: _medalCard(
                                  context,
                                  'Silver',
                                  18,
                                  Colors.blueGrey[200]!,
                                  'assets/images/SilverMedal.png',
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ), // Add spacing if required
                              Expanded(
                                child: _medalCard(
                                  context,
                                  'Bronze',
                                  11,
                                  Colors.brown[300]!,
                                  'assets/images/BronzeMedal.png',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          const SizedBox(height: 24),

                          // Certifications Section
                          // Certifications Section
                          // Certifications Section
                          _sectionTitle('MILESTONES', 8),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children:
                                  milestones.map((milestone) {
                                    return _certCard(
                                      context,
                                      milestone.label,
                                      milestone.cert,
                                      milestone.color,
                                      milestone.current,
                                      milestone.total,
                                      milestone.icon,
                                    );
                                  }).toList(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Badges Section
                          // Badges Section
                          _sectionTitle('BADGES', 0),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _badgeCircle(
                                  BadgeData(
                                    label: 'Top Contributor',
                                    description: 'Help 10 neighbors',
                                    lottiePath: 'assets/images/eP6yULpjL9.json',
                                    unlocked: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _badgeCircle(
                                  BadgeData(
                                    label: 'Community Hero',
                                    description: 'Help 25 neighbors',
                                    lottiePath:
                                        'assets/images/Knightsglove.json',
                                    unlocked: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _badgeCircle(
                                  BadgeData(
                                    label: 'Neighborhood Helper',
                                    description: 'Help 50 neighbors',
                                    unlocked: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _badgeCircle(
                                  BadgeData(
                                    label: 'Kindness Star',
                                    description: 'Help 100 neighbors',
                                    unlocked: false,
                                  ),
                                ),
                              ),
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
          title,
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

  Widget _medalCard(
    BuildContext context,
    String label,
    int count,
    Color color,
    String imagePath,
  ) {
    return Container(
      width: getResponsiveCardWidth(
        context,
        fraction: 0.28,
        min: 90,
        max: 140,
      ), // card sizing
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ), //vertically resize kore
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Bottom-right shadow
          BoxShadow(
            color: const Color(0xFFA6ABBD).withOpacity(0.5),
            blurRadius: 18.58,
            offset: const Offset(2.48, 2.48), // Shadow (bottomright)
          ),
          // Upperleft shadow
          BoxShadow(
            color: const Color(0xFFFAFBFF), // light blue shadow
            blurRadius: 16.1,
            offset: const Offset(-1.24, -1.24), // Shadow (upperleft)
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(imagePath, width: 50, height: 50),
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
  Widget _certCard(
    BuildContext context,
    String title,
    String cert,
    Color color,
    int current,
    int total,
    IconData icon,
  ) {
    double progress = current / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icon container
          // Icon or image container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                title == 'Gold Guardian'
                    ? Image.asset(
                      'assets/images/Medallions.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    )
                    : Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),

          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 8),

                // Progress bar (THICKER)
                // Progress bar (THICKER)
                Container(
                  width: double.infinity, // <-- FIXED WIDTH FOR ALL
                  height: 10,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        progress, // <-- MATHEMATICAL PROGRESS (0.0 to 1.0)
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Progress fraction (CHANGED FROM PERCENTAGE)
          Text(
            '$current/$total ${cert.split(' ')[0]}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Badge Card Widget
  Widget _badgeCard(
    BuildContext context,
    String label, {
    String? imagePath,
    IconData? icon,
    String? lottiePath,
  }) {
    return Container(
      width: getResponsiveCardWidth(context, fraction: 0.28, min: 90, max: 140),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lottiePath != null)
            SizedBox(
              width: 48,
              height: 48,
              child: Lottie.asset(
                lottiePath,
                fit: BoxFit.contain,
                repeat: true,
              ),
            )
          else if (imagePath != null)
            ClipOval(
              child: Image.asset(
                imagePath,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else if (icon != null)
            Icon(icon, color: Colors.purple, size: 44),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _badgeCircle(BadgeData badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badge.unlocked ? Colors.white : Colors.grey[200],
                  border: Border.all(
                    color:
                        badge.unlocked ? Color(0xFF5B5B7E) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child:
                    (badge.unlocked && badge.lottiePath != null)
                        ? Lottie.asset(
                          badge.lottiePath!,
                          fit: BoxFit.contain,
                          repeat: true,
                        )
                        : Icon(Icons.lock, color: Colors.grey[400], size: 32),
              ),
              if (!badge.unlocked)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 110,
            child: Text(
              badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: badge.unlocked ? Color(0xFF5B5B7E) : Colors.grey,
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}


//certcard, medalCard, badgeCard