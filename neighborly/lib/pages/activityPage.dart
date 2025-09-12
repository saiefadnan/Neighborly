import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

List<Map<String, dynamic>> acceptedHelpRequests = [];
List<Map<String, dynamic>> userPosts = []; // ← ADD THIS LINE
Map<String, dynamic>? badgeData;
bool isLoading = true;

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Map<String, dynamic>> acceptedHelpRequests = [];
  Map<String, dynamic>? badgeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityData();
  }

  // Fetch both accepted help requests and badge data
  // Fetch both accepted help requests and badge data
  Future<void> _fetchActivityData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _fetchAcceptedHelpRequests(),
      _fetchBadgeData(),
      _fetchUserPosts(), // ← ADD THIS LINE
    ]);

    setState(() {
      isLoading = false;
    });

    // Debug prints
    // Debug prints
    print('=== ACTIVITY DATA LOADED ===');
    print('acceptedHelpRequests: ${acceptedHelpRequests.length}');
    print('userPosts: ${userPosts.length}');
    print('badgeData: $badgeData');
    print('==========================');
  }

  // Fetch badge data for medals
  Future<void> _fetchBadgeData() async {
    try {
      bool success = false;

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
              setState(() {
                badgeData = data['data'];
              });
              success = true;
              print('Fetched badge data from API: $badgeData');
            }
          }
        }
      } catch (e) {
        print('Badge API fetch failed, trying Firestore fallback. Error: $e');
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Get helpedRequests for medal counts
            final helpedQuery =
                await FirebaseFirestore.instance
                    .collection('helpedRequests')
                    .where('acceptedUserID', isEqualTo: user.uid)
                    .where('status', whereIn: ['completed', 'in_progress'])
                    .get();

            // Get posts for Community Hero
            final postsQuery =
                await FirebaseFirestore.instance
                    .collection('posts')
                    .where('authorID', isEqualTo: user.uid)
                    .get();

            // Count medals by type
            int bronzeCount = 0;
            int goldCount = 0;
            int otherCount = 0;

            for (var doc in helpedQuery.docs) {
              final data = doc.data();
              final type = data['originalRequestData']?['type'] ?? 'Unknown';

              if (type == 'General') {
                bronzeCount++;
              } else if (type == 'Emergency') {
                goldCount++;
              } else {
                otherCount++;
              }
            }

            setState(() {
              badgeData = {
                'badges': {
                  'Bronze': bronzeCount,
                  'Gold': goldCount,
                  'Other': otherCount,
                  'CommunityHero': postsQuery.docs.length >= 3 ? 1 : 0,
                  'Kindstart': helpedQuery.docs.isNotEmpty ? 1 : 0,
                },
              };
            });
            success = true;
            print('Fetched badge data from Firestore: $badgeData');
          }
        } catch (e) {
          print('Firestore badge fallback failed: $e');
        }
      }
    } catch (e) {
      print('Error fetching badge data: $e');
    }
  }

  // Fetch accepted help requests with HTTP API + Firestore fallback
  Future<void> _fetchAcceptedHelpRequests() async {
    try {
      bool success = false;

      // 1. Try HTTP API first
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          final uri = Uri.parse(
            '${ApiConfig.baseUrl}/api/activeT/user-accepted-help-requests',
          );
          final response = await http.get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              acceptedHelpRequests = List<Map<String, dynamic>>.from(
                data['acceptedRequests'],
              );
              success = true;
              print(
                'Fetched ${acceptedHelpRequests.length} accepted help requests from API',
              );
            }
          }
        }
      } catch (e) {
        print('API fetch failed, trying Firestore fallback. Error: $e');
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final helpedRequestsQuery =
                await FirebaseFirestore.instance
                    .collection('helpedRequests')
                    .where('acceptedUserID', isEqualTo: user.uid)
                    .get();

            List<Map<String, dynamic>> firestoreRequests = [];

            for (var doc in helpedRequestsQuery.docs) {
              final data = doc.data();

              // Format timestamp from Firestore
              String formattedAcceptedAt = 'Unknown date';
              if (data['acceptedAt'] != null) {
                try {
                  DateTime date;
                  if (data['acceptedAt'] is Timestamp) {
                    date = (data['acceptedAt'] as Timestamp).toDate();
                  } else {
                    date = DateTime.parse(data['acceptedAt'].toString());
                  }

                  formattedAcceptedAt = _formatTimestamp(date);
                } catch (e) {
                  print('Error formatting Firestore timestamp: $e');
                }
              }

              // Get requester info from originalRequestData
              final originalData = data['originalRequestData'] ?? {};

              firestoreRequests.add({
                'requestId': data['requestId'] ?? doc.id,
                'requesterUsername':
                    originalData['requesterUsername'] ?? 'Unknown User',
                'requesterId': originalData['requesterId'] ?? 'Unknown',
                'title': originalData['title'] ?? 'Help Request',
                'description': originalData['description'] ?? 'No description',
                'type': originalData['type'] ?? 'General',
                'priority': originalData['priority'] ?? 'normal',
                'address': originalData['address'] ?? 'Unknown location',
                'acceptedAt': formattedAcceptedAt,
                'originalAcceptedAt': data['acceptedAt'],
                'status': data['status'] ?? 'unknown',
              });
            }

            // Sort by timestamp (newest first)
            firestoreRequests.sort((a, b) {
              try {
                if (a['originalAcceptedAt'] != null &&
                    b['originalAcceptedAt'] != null) {
                  DateTime dateA =
                      a['originalAcceptedAt'] is Timestamp
                          ? (a['originalAcceptedAt'] as Timestamp).toDate()
                          : DateTime.parse(a['originalAcceptedAt'].toString());
                  DateTime dateB =
                      b['originalAcceptedAt'] is Timestamp
                          ? (b['originalAcceptedAt'] as Timestamp).toDate()
                          : DateTime.parse(b['originalAcceptedAt'].toString());
                  return dateB.compareTo(dateA);
                }
              } catch (e) {
                print('Error sorting: $e');
              }
              return 0;
            });

            acceptedHelpRequests = firestoreRequests;
            success = true;
            print(
              'Fetched ${acceptedHelpRequests.length} accepted help requests from Firestore',
            );
          }
        } catch (e) {
          print('Firestore fallback failed: $e');
        }
      }
    } catch (e) {
      print('Error fetching accepted help requests: $e');
    }
  }

  // Fetch user posts with HTTP API + Firestore fallback
  Future<void> _fetchUserPosts() async {
    try {
      bool success = false;

      // 1. Try HTTP API first
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          final uri = Uri.parse(
            '${ApiConfig.baseUrl}/api/activeT/user-active-posts',
          );
          final response = await http.get(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              userPosts = List<Map<String, dynamic>>.from(data['posts']);
              success = true;
              print('Fetched ${userPosts.length} user posts from API');
            }
          }
        }
      } catch (e) {
        print('Posts API fetch failed, trying Firestore fallback. Error: $e');
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final postsQuery =
                await FirebaseFirestore.instance
                    .collection('posts')
                    .where('authorID', isEqualTo: user.uid)
                    .get();

            List<Map<String, dynamic>> firestorePosts = [];

            for (var doc in postsQuery.docs) {
              final data = doc.data();

              // Format timestamp from Firestore
              String formattedTimestamp = 'Unknown date';
              if (data['timestamp'] != null) {
                try {
                  DateTime date;
                  if (data['timestamp'] is Timestamp) {
                    date = (data['timestamp'] as Timestamp).toDate();
                  } else {
                    date = DateTime.parse(data['timestamp'].toString());
                  }

                  formattedTimestamp = _formatTimestamp(date);
                } catch (e) {
                  print('Error formatting Firestore timestamp: $e');
                }
              }

              firestorePosts.add({
                'postId': doc.id,
                'title': data['title'] ?? 'Untitled Post',
                'category': data['category'] ?? 'General',
                'type': data['type'] ?? 'text',
                'timestamp': formattedTimestamp,
                'originalTimestamp': data['timestamp'],
                'upvotes': data['upvotes'] ?? 0,
                'totalComments': data['totalComments'] ?? 0,
                'reacts': data['reacts'] ?? 0,
              });
            }

            // Sort by timestamp (newest first)
            firestorePosts.sort((a, b) {
              try {
                if (a['originalTimestamp'] != null &&
                    b['originalTimestamp'] != null) {
                  DateTime dateA =
                      a['originalTimestamp'] is Timestamp
                          ? (a['originalTimestamp'] as Timestamp).toDate()
                          : DateTime.parse(a['originalTimestamp'].toString());
                  DateTime dateB =
                      b['originalTimestamp'] is Timestamp
                          ? (b['originalTimestamp'] as Timestamp).toDate()
                          : DateTime.parse(b['originalTimestamp'].toString());
                  return dateB.compareTo(dateA);
                }
              } catch (e) {
                print('Error sorting posts: $e');
              }
              return 0;
            });

            userPosts = firestorePosts;
            success = true;
            print('Fetched ${userPosts.length} user posts from Firestore');
          }
        } catch (e) {
          print('Firestore posts fallback failed: $e');
        }
      }
    } catch (e) {
      print('Error fetching user posts: $e');
    }
  }

  // Helper function to format timestamp
  String _formatTimestamp(DateTime date) {
    try {
      // Format: August 30, 2025 at 1:18 AM
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final month = months[date.month];
      final day = date.day;
      final year = date.year;

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$month $day, $year at $hour:$minute $amPm';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Generate medal certification messages
  String _getMedalCertificationMessage(String medalType, int currentCount) {
    const int requiredCount = 5;

    if (currentCount >= requiredCount) {
      return "Congratulations! You are $medalType certified";
    } else {
      final remaining = requiredCount - currentCount;
      if (remaining == 1) {
        return "$remaining more to get $medalType certified! Almost there";
      } else if (remaining == 2) {
        return "$remaining more to get $medalType certified! Almost there";
      } else {
        return "$remaining more to get $medalType certified! Keep going";
      }
    }
  }

  // Generate individual medal XP messages
  String _getIndividualMedalMessage(String medalType, int count) {
    if (count > 0) {
      final xpPerMedal =
          medalType == 'Gold'
              ? 500
              : medalType == 'Silver'
              ? 300
              : 200;
      final totalXP = count * xpPerMedal;
      return "Earned $medalType $totalXP XP";
    } else {
      return "No $medalType medals earned yet";
    }
  }

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

            // Loading indicator
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Dynamic accepted help requests
            // DEBUG INFO

            // Dynamic accepted help requests
            if (!isLoading)
              ...acceptedHelpRequests
                  .map(
                    (request) => _buildAchievementItem(
                      title:
                          "${request['requesterUsername']} accepted your help",
                      subtitle: request['acceptedAt'],
                      image: 'assets/images/PostTestComplete.png',
                    ),
                  )
                  ,

            // Dynamic medal certification messages
            // Dynamic medal certification messages
            // Dynamic medal certification messages
            if (!isLoading && badgeData != null) ...[
              // Gold Certification - only show if user has at least 1 Gold medal
              if ((badgeData!['badges']['Gold'] ?? 0) > 0) ...[
                _buildAchievementItem(
                  title: _getMedalCertificationMessage(
                    'Gold',
                    badgeData!['badges']['Gold'] ?? 0,
                  ),
                  subtitle: "Emergency help certification",
                  image: 'assets/images/Medallions.png',
                ),
                // Gold individual medal XP
                _buildAchievementItem(
                  title: _getIndividualMedalMessage(
                    'Gold',
                    badgeData!['badges']['Gold'] ?? 0,
                  ),
                  subtitle: "Emergency help rewards",
                  image: 'assets/images/GoldMedal.png',
                ),
              ],

              // Bronze Certification - only show if user has at least 1 Bronze medal
              if ((badgeData!['badges']['Bronze'] ?? 0) > 0) ...[
                _buildAchievementItem(
                  title: _getMedalCertificationMessage(
                    'Bronze',
                    badgeData!['badges']['Bronze'] ?? 0,
                  ),
                  subtitle: "General help certification",
                  image: 'assets/images/Medallions.png',
                ),
                // Bronze individual medal XP
                _buildAchievementItem(
                  title: _getIndividualMedalMessage(
                    'Bronze',
                    badgeData!['badges']['Bronze'] ?? 0,
                  ),
                  subtitle: "General help rewards",
                  image: 'assets/images/BronzeMedal.png',
                ),
              ],

              // Silver Certification - only show if user has at least 1 Silver medal
              if ((badgeData!['badges']['Other'] ?? 0) > 0) ...[
                _buildAchievementItem(
                  title: _getMedalCertificationMessage(
                    'Silver',
                    badgeData!['badges']['Other'] ?? 0,
                  ),
                  subtitle: "Special help certification",
                  image: 'assets/images/Medallions.png',
                ),
                // Silver individual medal XP
                _buildAchievementItem(
                  title: _getIndividualMedalMessage(
                    'Silver',
                    badgeData!['badges']['Other'] ?? 0,
                  ),
                  subtitle: "Special help rewards",
                  image: 'assets/images/SilverMedal.png',
                ),
              ],
            ],

            // Other static items
            // Dynamic user posts
            if (!isLoading)
              ...userPosts
                  .map(
                    (post) => _buildAchievementItem(
                      title: "You posted '${post['title']}' in community",
                      subtitle: post['timestamp'],
                      image: 'assets/images/PostTestComplete.png',
                    ),
                  )
                  ,

            // Show message if no accepted help requests
            if (!isLoading && acceptedHelpRequests.isEmpty)
              _buildAchievementItem(
                title: "No accepted help requests yet",
                subtitle: "Help others to see activity here",
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
          SizedBox(
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
