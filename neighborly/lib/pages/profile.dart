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
import 'package:cloud_firestore/cloud_firestore.dart';

// Add these functions before the build method in ProfilePage class

// Level calculation functions
Map<String, dynamic> calculateLevel(int accumulateXP) {
  final List<int> xpRequirements = [
    0, // Level 1 starts at 0
    1000, // Level 1 to 2: 1000 XP
    3500, // Level 2 to 3: 2500 more (1000 + 2500)
    8500, // Level 3 to 4: 5000 more (3500 + 5000)
    16500, // Level 4 to 5: 8000 more
    28500, // Level 5 to 6: 12000 more
    45500, // Level 6 to 7: 17000 more
    68500, // Level 7 to 8: 23000 more
    98500, // Level 8 to 9: 30000 more
    136500, // Level 9 to 10: 38000 more
  ];

  int currentLevel = 1;
  for (int i = 1; i < xpRequirements.length; i++) {
    if (accumulateXP >= xpRequirements[i]) {
      currentLevel = i + 1;
    } else {
      break;
    }
  }

  int nextLevel = currentLevel < 10 ? currentLevel + 1 : 10;
  int currentLevelXP = currentLevel > 1 ? xpRequirements[currentLevel - 1] : 0;
  int nextLevelXP =
      currentLevel < 10 ? xpRequirements[currentLevel] : xpRequirements[9];
  int xpInCurrentLevel = accumulateXP - currentLevelXP;
  int xpNeededForNext = nextLevelXP - currentLevelXP;
  int xpToNext = nextLevelXP - accumulateXP;
  double progress =
      currentLevel >= 10 ? 1.0 : (xpInCurrentLevel / xpNeededForNext);

  return {
    'currentLevel': currentLevel,
    'nextLevel': nextLevel,
    'currentXP': accumulateXP,
    'nextLevelXP': nextLevelXP,
    'xpToNext': xpToNext,
    'progress': progress,
  };
}

// Fetch user XP data
// Fetch user XP data
// Fetch user XP data
Future<Map<String, dynamic>?> fetchUserXP() async {
  // Run migration first
  await _migrateUserXPWithFallback();
  
  bool success = false;
  Map<String, dynamic>? result;

  // Rest of your existing fetchUserXP code...
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/gamification/user/xp');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          result = data['data'];
          success = true;
        }
      }
    }
  } catch (e) {
    print('XP API fetch failed, will try Firestore. Error: $e');
  }

  // ... rest of existing code for Firestore fallback


  // 2. If API failed, try Firestore directly
  if (!success) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get user document from Firestore
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final accumulateXP = userData['accumulateXP'] ?? 0;
        final level = userData['level'] ?? 1;

        result = {
          'userId': user.uid,
          'username': userData['displayName'] ?? 'Anonymous User',
          'profilepicurl': userData['profilepicurl'], // ← Add this
          'accumulateXP': accumulateXP,
          'level': level,
          'lastUpdated':
              userData['xpAndLevelMigratedAt'] ?? userData['updatedAt'],
        };

        print(
          'Fetched XP data from Firestore: XP: $accumulateXP, Level: $level',
        );
      }
    } catch (e) {
      print('Error fetching user XP from Firestore: $e');
    }
  }

  return result;
}

// Add this function after fetchUserXP() function
// Add this function after fetchUserXP() function
Future<Map<String, dynamic>?> fetchUserBadges() async {
  bool success = false;
  Map<String, dynamic>? result;

  // 1. Try HTTP API first
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/gamification/user/badges',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          result = data['data'];
          success = true;
        }
      }
    }
  } catch (e) {
    print('Badge API fetch failed, will try Firestore. Error: $e');
  }

  // 2. If API failed, try Firestore directly
  if (!success) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Get all helpedRequests for this user from Firestore
      final helpedRequestsQuery =
          await FirebaseFirestore.instance
              .collection('helpedRequests')
              .where('acceptedUserID', isEqualTo: user.uid)
              .where('status', whereIn: ['completed', 'in_progress'])
              .get();

      // Get ALL helpedRequests for Kindstart badge (any status)
      final allHelpedRequestsQuery =
          await FirebaseFirestore.instance
              .collection('helpedRequests')
              .where('acceptedUserID', isEqualTo: user.uid)
              .get();

      // Get user's posts for Community Hero badge
      final postsQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('authorID', isEqualTo: user.uid)
              .get();

      int bronzeCount = 0; // General type
      int goldCount = 0; // Emergency type
      int otherCount = 0; // Other types

      final helpDetails = <Map<String, dynamic>>[];

      // Count medals based on completed/in_progress helps only
      for (final doc in helpedRequestsQuery.docs) {
        final data = doc.data();
        final type = data['originalRequestData']?['type'] ?? 'Unknown';

        // Count based on type
        if (type == 'General') {
          bronzeCount++;
        } else if (type == 'Emergency') {
          goldCount++;
        } else {
          otherCount++;
        }

        // Collect details for debugging
        helpDetails.add({
          'requestId': data['requestId'],
          'type': type,
          'status': data['status'],
          'acceptedAt': data['acceptedAt'],
          'xp': data['xp'] ?? 0,
        });
      }

      // Calculate badge unlock status
      final totalHelpCount = allHelpedRequestsQuery.docs.length;
      final postCount = postsQuery.docs.length;
      final kindstartUnlocked = totalHelpCount >= 1;
      final communityHeroUnlocked = postCount >= 3;

      result = {
        'userId': user.uid,
        'badges': {
          'Bronze': bronzeCount,
          'Gold': goldCount,
          'Other': otherCount,
          'CommunityHero': communityHeroUnlocked ? 1 : 0,
          'Kindstart': kindstartUnlocked ? 1 : 0,
        },
        'helpCount': totalHelpCount,
        'postCount': postCount,
        'communityHeroUnlocked': communityHeroUnlocked,
        'kindstartUnlocked': kindstartUnlocked,
        'totalHelps': bronzeCount + goldCount + otherCount,
        'helpDetails': helpDetails,
      };

      print(
        'Fetched badge data from Firestore: Bronze: $bronzeCount, Gold: $goldCount, Other: $otherCount, Kindstart: $kindstartUnlocked, CommunityHero: $communityHeroUnlocked',
      );
    } catch (e) {
      print('Error fetching user badges from Firestore: $e');
    }
  }

  return result;
}

Future<void> _migrateUserXPWithFallback() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool success = false;

    // 1. Try HTTP API first
    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/gamification/migrate-xp-levels'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('XP migration completed via API: ${data['message']}');
          success = true;
        }
      }
    } catch (e) {
      print('Migration API failed, trying Firestore fallback. Error: $e');
    }

    // 2. Firestore fallback if API failed
    if (!success) {
      await _migrateUserXPFirestore();
    }
  } catch (e) {
    print('Error in migration: $e');
  }
}

Future<void> _migrateUserXPFirestore() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if migration already happened recently (within 1 hour)
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final lastMigration = userData['xpAndLevelMigratedAt'];

      if (lastMigration != null) {
        final lastMigrationTime = DateTime.parse(lastMigration);
        final now = DateTime.now();
        final difference = now.difference(lastMigrationTime).inMinutes;

        // Skip migration if done within last 60 minutes
        if (difference < 60) {
          print('Migration skipped - done ${difference} minutes ago');
          return;
        }
      }
    }

    // Get all helpedRequests for current user
    final helpedRequestsSnapshot =
        await FirebaseFirestore.instance
            .collection('helpedRequests')
            .where('acceptedUserID', isEqualTo: user.uid)
            .where('status', whereIn: ['completed', 'in_progress'])
            .get();

    // Calculate total XP
    int totalXP = 0;
    for (final doc in helpedRequestsSnapshot.docs) {
      final data = doc.data();
      final xp = data['xp'] ?? 0;
      totalXP += xp is int ? xp : int.tryParse(xp.toString()) ?? 0;
    }

    // Calculate level
    int calculatedLevel = _calculateLevel(totalXP);

    // Update user document
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'accumulateXP': totalXP,
      'level': calculatedLevel,
      'xpAndLevelMigratedAt': DateTime.now().toIso8601String(),
    });

    print('Firestore migration completed: XP=$totalXP, Level=$calculatedLevel');
  } catch (e) {
    print('Firestore migration failed: $e');
  }
}

int _calculateLevel(int accumulateXP) {
  final List<int> xpRequirements = [
    0,
    1000,
    3500,
    8500,
    16500,
    28500,
    45500,
    68500,
    98500,
    136500,
  ];

  int currentLevel = 1;
  for (int i = 1; i < xpRequirements.length; i++) {
    if (accumulateXP >= xpRequirements[i]) {
      currentLevel = i + 1;
    } else {
      break;
    }
  }
  return currentLevel;
}

// Replace the existing milestones list with this function
// Replace the existing milestones list with this function
List<MilestoneData> getMilestones(Map<String, dynamic>? badgeData) {
  final bronzeCount = badgeData?['badges']?['Bronze'] ?? 0; // General type
  final silverCount =
      badgeData?['badges']?['Other'] ?? 0; // Other types = Silver
  final goldCount = badgeData?['badges']?['Gold'] ?? 0; // Emergency type
  return [
    MilestoneData(
      label: 'Rookie Hero',
      cert: 'Bronze Certified',
      color: Colors.brown[400]!,
      icon: bronzeCount >= 5 ? Icons.verified : Icons.hourglass_bottom,
      current: bronzeCount,
      total: 5,
    ),
    MilestoneData(
      label: 'Silver Surfer',
      cert: 'Silver Certified',
      color: Colors.blueGrey[400]!,
      icon: silverCount >= 5 ? Icons.verified : Icons.hourglass_bottom,
      current: silverCount,
      total: 5,
    ),
    MilestoneData(
      label: 'Gold Guardian',
      cert: 'Gold Certified',
      color: Colors.amber[400]!,
      icon: goldCount >= 5 ? Icons.verified : Icons.hourglass_bottom,
      current: goldCount,
      total: 5,
    ),
  ];
}

// Add this function after getMilestones()

Map<String, int> getMedalCounts(Map<String, dynamic>? badgeData) {
  final bronzeCount = badgeData?['badges']?['Bronze'] ?? 0; // General type
  final goldCount = badgeData?['badges']?['Gold'] ?? 0; // Emergency type
  final silverCount =
      badgeData?['badges']?['Other'] ?? 0; // Other types = Silver

  return {'Bronze': bronzeCount, 'Silver': silverCount, 'Gold': goldCount};
}

// Get badge unlock status based on API data
Map<String, bool> getBadgeUnlockStatus(Map<String, dynamic>? badgeData) {
  final kindstartUnlocked = badgeData?['kindstartUnlocked'] ?? false;
  final communityHeroUnlocked = badgeData?['communityHeroUnlocked'] ?? false;

  return {
    'Kindstart': kindstartUnlocked,
    'CommunityHero': communityHeroUnlocked,
    'NeighborhoodHelper': false, // Not implemented yet
    'KindnessStar': false, // Not implemented yet
  };
}

// Add this function specifically for profile picture only
Future<String?> fetchUserProfilePicture() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/infos');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        return data['profilepicurl'];
      }
    }
  } catch (e) {
    print('Error fetching profile picture from API, trying Firestore: $e');

    // Firestore fallback for profile picture only
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          return userData['profilepicurl'];
        }
      }
    } catch (e) {
      print('Error fetching profile picture from Firestore: $e');
    }
  }
  return null;
}

class _ProfileNameHeader extends StatefulWidget {
  const _ProfileNameHeader();

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

      bool success = false;

      // 1. Try HTTP API first
      try {
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
          success = true;
          print('Fetched user name from API: $_name');
        }
      } catch (e) {
        print('Name API fetch failed, trying Firestore fallback. Error: $e');
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            final username = userData['username'] ?? '';

            // Try firstName + lastName first, then username as fallback
            String name = (firstName + ' ' + lastName).trim();
            if (name.isEmpty) {
              name = username;
            }

            setState(() {
              _name = name.isNotEmpty ? name : 'Unknown User';
              _loading = false;
            });
            print('Fetched user name from Firestore: $_name');
          } else {
            setState(() {
              _name = 'Unknown User';
              _loading = false;
            });
          }
        } catch (e) {
          print('Firestore name fallback failed: $e');
          setState(() {
            _name = 'Unknown User';
            _loading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user info: $e');
      if (mounted) {
        setState(() {
          _name = 'Unknown User';
          _loading = false;
        });
      }
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
                  FutureBuilder<String?>(
                    future: fetchUserProfilePicture(),
                    builder: (context, snapshot) {
                      String? profilePicUrl = snapshot.data;

                      return CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? NetworkImage(profilePicUrl)
                                : AssetImage('assets/images/dummy.png')
                                    as ImageProvider,
                        onBackgroundImageError:
                            profilePicUrl != null && profilePicUrl.isNotEmpty
                                ? (exception, stackTrace) {
                                  print(
                                    'Error loading profile image: $exception',
                                  );
                                }
                                : null,
                      );
                    },
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
                          // Level Card
                          FutureBuilder<Map<String, dynamic>?>(
                            future: fetchUserXP(),
                            builder: (context, snapshot) {
                              // Default values for loading/error state
                              Map<String, dynamic> levelData = calculateLevel(
                                0,
                              );

                              if (snapshot.hasData && snapshot.data != null) {
                                final accumulateXP =
                                    snapshot.data!['accumulateXP'] ?? 0;
                                levelData = calculateLevel(accumulateXP);
                              }

                              return Container(
                                width: MediaQuery.of(context).size.width * 0.92,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: const Color(
                                                0xFF5B5B7E,
                                              ),
                                              child: Text(
                                                '${levelData['currentLevel']}',
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
                                              children: [
                                                Text(
                                                  'Level ${levelData['currentLevel']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  levelData['currentLevel'] >=
                                                          10
                                                      ? 'Max Level Reached!'
                                                      : '${levelData['xpToNext']} Points to next level',
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
                                            borderRadius: BorderRadius.circular(
                                              19,
                                            ),
                                          ),
                                        ),
                                        // Progress bar background
                                        Positioned(
                                          left: 19,
                                          right: 19,
                                          child: Container(
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF2E6C3),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        // Progress bar (Dynamic width)
                                        Positioned(
                                          left: 19,
                                          right:
                                              19 +
                                              ((1.0 - levelData['progress']) *
                                                  312),
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                        // Left circle (current level)
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
                                            child: Center(
                                              child: Text(
                                                '${levelData['currentLevel']}',
                                                style: TextStyle(
                                                  color: Color(0xFF5B5B7E),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Right circle (next level)
                                        Positioned(
                                          right: 0,
                                          child: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color:
                                                  levelData['currentLevel'] >=
                                                          10
                                                      ? const Color(0xFFFFD966)
                                                      : const Color(0xFFFFF3CD),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Color(0xFFF2E6C3),
                                                width: 3,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${levelData['nextLevel']}',
                                                style: TextStyle(
                                                  color:
                                                      levelData['currentLevel'] >=
                                                              10
                                                          ? Color(0xFF5B5B7E)
                                                          : Color(0xFFBBA86B),
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
                                                  color: const Color(
                                                    0xFFEECF60,
                                                  ),
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 6),
                                                RichText(
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${levelData['currentXP']}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.brown[700],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            levelData['currentLevel'] >=
                                                                    10
                                                                ? ' MAX'
                                                                : '/${levelData['nextLevelXP']}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.brown[300],
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
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // Medals Section
                          // Medals Section
                          FutureBuilder<Map<String, dynamic>?>(
                            future: fetchUserBadges(),
                            builder: (context, snapshot) {
                              final medalCounts = getMedalCounts(snapshot.data);
                              final totalMedals =
                                  medalCounts['Gold']! +
                                  medalCounts['Silver']! +
                                  medalCounts['Bronze']!;

                              return Column(
                                children: [
                                  _sectionTitle('HONORS', totalMedals),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: _medalCard(
                                          context,
                                          'Gold',
                                          medalCounts['Gold']!,
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
                                          medalCounts['Silver']!,
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
                                          medalCounts['Bronze']!,
                                          Colors.brown[300]!,
                                          'assets/images/BronzeMedal.png',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          const SizedBox(height: 24),

                          // Certifications Section
                          // Certifications Section
                          // Certifications Section
                          // Certifications Section
                          FutureBuilder<Map<String, dynamic>?>(
                            future: fetchUserBadges(),
                            builder: (context, snapshot) {
                              final milestones = getMilestones(snapshot.data);
                              final completedMilestones =
                                  milestones
                                      .where((m) => m.current >= m.total)
                                      .length;

                              return _sectionTitle(
                                'MILESTONES',
                                completedMilestones,
                              ); // ← Dynamic count
                            },
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<Map<String, dynamic>?>(
                            future: fetchUserBadges(),
                            builder: (context, snapshot) {
                              // Get milestones based on API data
                              final milestones = getMilestones(snapshot.data);

                              return Container(
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
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Badges Section
                          // Badges Section
                          // Badges Section
                          FutureBuilder<Map<String, dynamic>?>(
                            future: fetchUserBadges(),
                            builder: (context, snapshot) {
                              final badgeStatus = getBadgeUnlockStatus(
                                snapshot.data,
                              );
                              final badgeCount =
                                  badgeStatus.values
                                      .where((unlocked) => unlocked)
                                      .length;

                              return Column(
                                children: [
                                  _sectionTitle('BADGES', badgeCount),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: _badgeCircle(
                                          BadgeData(
                                            label: 'Kind\nStart',
                                            description: 'Help 1+ person',
                                            lottiePath:
                                                'assets/images/eP6yULpjL9.json',
                                            unlocked:
                                                badgeStatus['Kindstart'] ??
                                                false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _badgeCircle(
                                          BadgeData(
                                            label: 'Community Hero',
                                            description: 'Post 3+ times',
                                            lottiePath:
                                                'assets/images/Knightsglove.json',
                                            unlocked:
                                                badgeStatus['CommunityHero'] ??
                                                false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _badgeCircle(
                                          BadgeData(
                                            label: 'Neighborhood Helper',
                                            description: 'Coming Soon',
                                            unlocked:
                                                badgeStatus['NeighborhoodHelper'] ??
                                                false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _badgeCircle(
                                          BadgeData(
                                            label: 'Kindness Star',
                                            description: 'Coming Soon',
                                            unlocked:
                                                badgeStatus['KindnessStar'] ??
                                                false,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
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
          if (badge.description.isNotEmpty)
            SizedBox(
              width: 110,
              child: Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: badge.unlocked ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


//certcard, medalCard, badgeCard