import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//  for cos and sin functions

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  Map<String, int> helpRequestStats = {};
  Map<String, int> helpedRequestStats = {};
  int successfulHelpsCount = 0; // ← ADD THIS LINE
  int userRank = 0; // ← ADD THIS LINE
  int helpResponseSuccess = 0; // ← ADD THIS LINE
  bool isLoadingStats = true;
  // Declare AnimationControllers for each card
  late AnimationController _breathingController1;
  late AnimationController _breathingController2;
  late AnimationController _breathingController3;
  late AnimationController _breathingController4;

  late Animation<double> _breathingAnimation1;
  late Animation<double> _breathingAnimation2;
  late Animation<double> _breathingAnimation3;
  late Animation<double> _breathingAnimation4;

  Future<void> _fetchHelpRequestStats() async {
    setState(() {
      isLoadingStats = true;
    });

    bool success = false;

    // 1. Try HTTP API first
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/stats/help-request-counts'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              helpRequestStats = Map<String, int>.from(data['data']);
              isLoadingStats = false;
            });
            success = true;
          }
        }
      }
    } catch (e) {
      print('API fetch failed, will try Firestore. Error: $e');
    }

    // 2. If API failed, try Firestore directly
    if (!success) {
      try {
        final snapshot =
            await FirebaseFirestore.instance.collection('helpRequests').get();
        final Map<String, int> counts = {};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final title = data['title'] ?? 'Unknown';
          counts[title] = (counts[title] ?? 0) + 1;
        }

        setState(() {
          helpRequestStats = counts;
          isLoadingStats = false;
        });
      } catch (e) {
        print('Error fetching help request stats from Firestore: $e');
        if (!mounted) return;
        setState(() {
          isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _fetchHelpedRequestStats() async {
    bool success = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/stats/helped-request-counts'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              helpedRequestStats = Map<String, int>.from(data['data']);
            });
            success = true;
          }
        }
      }
    } catch (e) {
      print('Error fetching helped request stats: $e');
    }

    // Firestore fallback if API fails
    if (!success) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final snapshot =
              await FirebaseFirestore.instance
                  .collection('helpRequests')
                  .where('acceptedResponderId', isEqualTo: user.uid)
                  .get();

          final Map<String, int> counts = {};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final title = data['title'] ?? 'Unknown';
            counts[title] = (counts[title] ?? 0) + 1;
          }

          setState(() {
            helpedRequestStats = counts;
          });
        }
      } catch (e) {
        print('Firestore fallback for helped request stats failed: $e');
      }
    }
  }

  Future<void> _fetchSuccessfulHelpsCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();

        // 1. Try HTTP API first
        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/stats/user-successful-helps'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              setState(() {
                successfulHelpsCount = data['count'] ?? 0;
              });
              print(
                'Fetched successful helps count from API: $successfulHelpsCount',
              );
              return;
            }
          }
        } catch (e) {
          print('API fetch failed, trying Firestore fallback. Error: $e');
        }

        // 2. Firestore fallback if API failed
        try {
          final helpRequestsSnapshot =
              await FirebaseFirestore.instance.collection('helpRequests').get();

          int count = 0;
          for (var doc in helpRequestsSnapshot.docs) {
            final data = doc.data();
            final acceptedResponderId = data['acceptedResponderId'];
            final acceptedResponderUserId = data['acceptedResponderUserId'];

            if (acceptedResponderId == user.uid ||
                acceptedResponderUserId == user.uid) {
              count++;
            }
          }

          setState(() {
            successfulHelpsCount = count;
          });
          print(
            'Fetched successful helps count from Firestore: $successfulHelpsCount',
          );
        } catch (e) {
          print('Firestore fallback failed: $e');
        }
      }
    } catch (e) {
      print('Error fetching successful helps count: $e');
    }
  }

  Future<void> _fetchUserRank() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();

        // 1. Try HTTP API first
        try {
          final response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/stats/leaderboard'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              setState(() {
                userRank = data['userRank'] ?? 0; // ← ADD THIS LINE
              });
              print('Fetched user rank from API: $userRank');
              return;
            }
          }
        } catch (e) {
          print(
            'Leaderboard API fetch failed, trying Firestore fallback. Error: $e',
          );
        }

        // 2. Firestore fallback if API failed
        try {
          final usersSnapshot =
              await FirebaseFirestore.instance.collection('users').get();

          // Create list of users with XP
          List<Map<String, dynamic>> usersWithXP = [];

          for (var doc in usersSnapshot.docs) {
            final data = doc.data();
            final accumulateXP = data['accumulateXP'] ?? 0;

            usersWithXP.add({'userId': doc.id, 'accumulateXP': accumulateXP});
          }

          // Sort by XP (highest first)
          usersWithXP.sort(
            (a, b) => b['accumulateXP'].compareTo(a['accumulateXP']),
          );

          // Find current user's rank
          int rank = 0;
          for (int i = 0; i < usersWithXP.length; i++) {
            if (usersWithXP[i]['userId'] == user.uid) {
              // Handle ties: find the rank of users with same XP
              int currentUserXP = usersWithXP[i]['accumulateXP'];
              rank = 1;
              for (int j = 0; j < i; j++) {
                if (usersWithXP[j]['accumulateXP'] > currentUserXP) {
                  rank++;
                }
              }
              break;
            }
          }

          setState(() {
            userRank = rank;
            // Calculate help response success: if user helped > 0, then 100%, otherwise 0%
          });
          print('Fetched user rank from Firestore: $userRank');
        } catch (e) {
          print('Firestore leaderboard fallback failed: $e');
        }
      }
    } catch (e) {
      print('Error fetching user rank: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize AnimationControllers
    _breathingController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _breathingController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _breathingController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _breathingController4 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Define breathing animations
    _breathingAnimation1 = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController1, curve: Curves.easeInOut),
    );
    _breathingAnimation2 = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController2, curve: Curves.easeInOut),
    );
    _breathingAnimation3 = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController3, curve: Curves.easeInOut),
    );
    _breathingAnimation4 = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController4, curve: Curves.easeInOut),
    );

    // Fetch data in sequence
    _fetchAllData();
  }

  // ADD this new method:
  Future<void> _fetchAllData() async {
    await _fetchHelpRequestStats();
    await _fetchHelpedRequestStats();
    await _fetchSuccessfulHelpsCount(); // ← Wait for this to complete first
    await _fetchUserRank(); // ← Then calculate percentage

    // Calculate help response success after all data is loaded
    setState(() {
      if (successfulHelpsCount > 0) {
        helpResponseSuccess = 100;
      } else {
        helpResponseSuccess = 0;
      }
    });

    print(
      'All data loaded. successfulHelpsCount: $successfulHelpsCount, helpResponseSuccess: $helpResponseSuccess',
    );
  }

  @override
  void dispose() {
    // Dispose the controllers
    _breathingController1.dispose();
    _breathingController2.dispose();
    _breathingController3.dispose();
    _breathingController4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Helped Requests & Neighborhood Rank
          Row(
            children: [
              _statCard(
                iconData: Icons.flash_on_outlined,
                label: '$successfulHelpsCount', // ← NOW DYNAMIC!
                subLabel: 'Helped\nRequests',
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9C64), Color(0xFFFF9C64)],
                ),
                iconColor: Colors.white,
                breathingAnimation: _breathingAnimation1,
              ),
              const SizedBox(width: 16),
              _statCard(
                iconData: Icons.leaderboard_outlined,
                label: userRank > 0 ? '#$userRank' : '#-', // ← NOW DYNAMIC!
                subLabel: 'Leaderboard\nRank',
                gradient: const LinearGradient(
                  colors: [Color(0xFFB084F4), Color(0xFFB084F4)],
                ),
                iconColor: Colors.white,
                breathingAnimation: _breathingAnimation2,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard(
                iconData: Icons.check_circle_outlined,
                label: '$helpResponseSuccess%', // ← NOW DYNAMIC!
                subLabel: 'Help Response\nSuccess',
                gradient: const LinearGradient(
                  colors: [Color(0xFFB8F46C), Color(0xFFB8F46C)],
                ),
                iconColor: Colors.white,
                breathingAnimation: _breathingAnimation3,
              ),
              const SizedBox(width: 16),
              _statCard(
                iconData: Icons.location_on_outlined,
                label: '2 km',
                subLabel: 'Help Range\nRadius',
                gradient: const LinearGradient(
                  colors: [Color(0xFF94D4FA), Color(0xFF94D4FA)],
                ),
                iconColor: Colors.white,
                breathingAnimation: _breathingAnimation4,
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Strongest Topics (all in one card)
          // Most Frequent Help Types (all in one card)
          const Text(
            'MOST REQUESTED HELP TYPES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _strongestTopicsCard(context),
          const SizedBox(height: 28),
          // Least Contributed Areas (single card)
          const Text(
            'CONTRIBUTIONS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _contributionsCard(),
          /* _topicCard(
            context: context,
            iconPath: null,
            iconData: Icons.traffic,
            label: 'Traffic Updates',
            percent: 0.95,
            percentLabel: '95%',
            color: Colors.green,
          ), */
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String subLabel,
    required IconData iconData,
    required Gradient gradient,
    Color iconColor = Colors.white,
    required Animation<double> breathingAnimation, // Add breathing animation
  }) {
    // same color mapping as before
    Color baseColor = Colors.white;
    if (label == '$successfulHelpsCount') {
      baseColor = const Color.fromARGB(255, 255, 146, 82);
    } else if (label == (userRank > 0 ? '#$userRank' : '#-')) {
      // ← UPDATE THIS
      baseColor = const Color.fromARGB(255, 155, 110, 224);
    } else if (label == '$helpResponseSuccess%') {
      // ← UPDATE THIS
      baseColor = const Color.fromARGB(255, 142, 218, 43);
    } else if (label == '2 km') {
      baseColor = const Color.fromARGB(255, 83, 171, 221);
    }

    return Expanded(
      child: AnimatedBuilder(
        animation: breathingAnimation,
        builder: (context, child) {
          // Breathing effect by scaling the card
          return Transform.scale(
            scale: breathingAnimation.value, // Apply breathing effect
            child: Container(
              height: 155,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor,
                    baseColor.withOpacity(0.85),
                    baseColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.25),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -15,
                    top: -15,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.10),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      iconData,
                      size: 70,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(iconData, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          alignment: Alignment.centerLeft,
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _strongestTopicsCard(BuildContext context) {
    // Map help types to icons (including all types you provided)
    final Map<String, IconData> helpTypeIcons = {
      'Grocery': Icons.shopping_cart,
      'Route': Icons.directions,
      'Pets': Icons.pets,
      'Medical': Icons.local_hospital,
      'Home Repair': Icons.home_repair_service,
      'School': Icons.school,
      'Restaurant': Icons.restaurant,
      'Traffic Update': Icons.traffic,
      'Fire': Icons.local_fire_department,
    };

    // If still loading, show loading indicator
    if (isLoadingStats) {
      return Container(
        height: 260, // Same height as before
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2FEA9B)),
        ),
      );
    }

    // Prepare chart data from real backend data
    // Prepare chart data from real backend data (filter out 0-count types)
    List<MapEntry<String, int>> sortedEntries =
        helpRequestStats.entries.where((entry) => entry.value > 0).toList()
          ..sort(
            (a, b) => b.value.compareTo(a.value),
          ); // Sort by count descending

    // If all are zero, show a message
    if (sortedEntries.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: const Text(
          "No help requests yet!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Build helpTypes list for the chart
    List<Map<String, dynamic>> helpTypes =
        sortedEntries.map((entry) {
          return {
            'label': entry.key,
            'icon': helpTypeIcons[entry.key] ?? Icons.help_outline,
            'active': entry.value.toDouble(),
          };
        }).toList();
    // Find max value for chart scaling
    double maxValue = helpTypes
        .map((e) => e['active'] as double)
        .reduce((a, b) => a > b ? a : b);
    maxValue = maxValue > 0 ? maxValue + 5 : 30; // Add padding or default to 30

    return Container(
      height: 260, // Same height as before
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: SizedBox(
          width: double.infinity,
          height: 180, // Same chart height as before
          child: BarChart(
            BarChartData(
              maxY: maxValue,
              minY: 0,
              barGroups: List.generate(helpTypes.length, (index) {
                final type = helpTypes[index];
                final count = type['active'] as double;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      fromY: 0,
                      toY: count,
                      width: 32, // Same bar width as before
                      color:
                          count > 0
                              ? const Color(0xFF2FEA9B)
                              : Colors.grey.shade300,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ],
                );
              }),
              groupsSpace: 8, // Same space between bars as before
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval:
                        maxValue > 20 ? (maxValue / 5).ceil().toDouble() : 5,
                    getTitlesWidget: (value, meta) {
                      if (value % (maxValue > 20 ? (maxValue / 5).ceil() : 5) ==
                              0 &&
                          value >= 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60, // Same space for bottom labels
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= helpTypes.length) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              helpTypes[idx]['icon'] as IconData,
                              size: 18, // Same icon size as before
                              color: Colors.black54,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(helpTypes[idx]['active'] as double).toInt()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(),
                topTitles: const AxisTitles(),
              ),
              gridData: FlGridData(
                horizontalInterval:
                    maxValue > 20 ? (maxValue / 5).ceil().toDouble() : 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: const BorderSide(color: Colors.transparent),
                  top: const BorderSide(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verticalBarWithLabel({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int value,
    required int max,
    required Color color,
  }) {
    double barHeight = 180;
    double fillHeight = (value / max) * barHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Faded background bar
            Container(
              width: 22,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                ),
              ),
            ),
            // Filled bar
            Container(
              width: 22,
              height: fillHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _topicChartRow({
    required BuildContext context,
    required String label,
    required int activeRequests, // Active requests
    required int inactiveRequests, // Inactive requests
    required Color activeColor,
    required Color inactiveColor,
  }) {
    return Column(
      children: [
        Icon(
          Icons.bar_chart,
          size: 32,
          color: activeColor,
        ), // Icon for each section
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // Stacked Bar Chart
        SizedBox(
          height: 50, // Adjust the height for the bar
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      fromY: 0, // Start from 0 (X-axis starts here)
                      toY:
                          activeRequests
                              .toDouble(), // Set height of the active bar
                      width: 30, // Bar width
                      color: activeColor, // Color for the active bar
                    ),
                    BarChartRodData(
                      fromY:
                          activeRequests
                              .toDouble(), // Start where active bar ends
                      toY:
                          (activeRequests + inactiveRequests)
                              .toDouble(), // Set height of inactive bar
                      width: 30, // Bar width
                      color: inactiveColor, // Color for the inactive bar
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _contributionsCard() {
    final List<_ContributionData> chartData = [
      _ContributionData(
        'Grocery',
        helpedRequestStats['Grocery'] ?? 0,
        const Color(0xFF4285F4),
      ),
      _ContributionData(
        'Transport',
        helpedRequestStats['Transport'] ?? 0,
        const Color(0xFF2FEA9B),
      ),
      _ContributionData(
        'Medical',
        helpedRequestStats['Medical'] ?? 0,
        const Color(0xFFFFB300),
      ),
      _ContributionData(
        'Other',
        helpedRequestStats['Other'] ?? 0,
        const Color(0xFFFFE082),
      ),
      _ContributionData(
        'Traffic',
        helpedRequestStats['Traffic'] ?? 0,
        const Color(0xFFE74C3C),
      ),
    ];

    // Sort the chartData in ascending order based on the value
    chartData.sort((a, b) => a.value.compareTo(b.value));

    final int total = chartData.fold(0, (sum, item) => sum + item.value);

    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Column(
        children: [
          // Radial Chart Section
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SfCircularChart(
                  margin: EdgeInsets.zero,
                  legend: Legend(isVisible: false),
                  series: <CircularSeries>[
                    RadialBarSeries<_ContributionData, String>(
                      dataSource: chartData,
                      xValueMapper: (_ContributionData data, _) => data.label,
                      yValueMapper: (_ContributionData data, _) => data.value,
                      pointColorMapper:
                          (_ContributionData data, _) => data.color,
                      maximumValue: total > 0 ? total.toDouble() : 1.0,
                      radius: '110%',
                      innerRadius: '17%',
                      gap: '7%',
                      cornerStyle: CornerStyle.bothCurve,
                      //explode: true,
                      //explodeIndex: 0,
                      dataLabelSettings: DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        labelIntersectAction:
                            LabelIntersectAction
                                .shift, // Smart labels like in your image
                        connectorLineSettings: ConnectorLineSettings(
                          type: ConnectorType.curve,
                          length: '10%',
                          width: 1.5,
                          color: Colors.grey.shade400,
                        ),
                        builder: (
                          dynamic data,
                          dynamic point,
                          dynamic series,
                          int pointIndex,
                          int seriesIndex,
                        ) {
                          final _ContributionData contribution =
                              data as _ContributionData;

                          // Don't show icon if value is 0
                          if (contribution.value <= 0) return Container();

                          final Map<String, IconData> helpTypeIcons = {
                            'Grocery': Icons.shopping_cart,
                            'Transport': Icons.directions_car,
                            'Medical': Icons.local_hospital,
                            'Other': Icons.help_outline,
                            'Traffic': Icons.traffic,
                          };

                          return Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: contribution.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: contribution.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              helpTypeIcons[contribution.label] ??
                                  Icons.help_outline,
                              size: 10,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Center text
                Text(
                  '$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: Color(0xFF5B5B7E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributionData {
  final String label;
  final int value;
  final Color color;
  _ContributionData(this.label, this.value, this.color);
}

// Custom painter for the ring segments

Widget _topicCard({
  required BuildContext context,
  String? iconPath,
  IconData? iconData,
  required String label,
  required double percent,
  required String percentLabel,
  required Color color,
  required int currentRequests,
  required int totalRequests,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
    ),
    child: Row(
      children: [
        iconPath != null
            ? Image.asset(iconPath, width: 32, height: 32, fit: BoxFit.cover)
            : Icon(iconData, size: 32, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Gradient progress bar
              // Gradient progress bar for Traffic Updates
              SizedBox(
                height: 200, // Adjust height as needed
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            fromY: 0, // start of the bar
                            toY:
                                currentRequests
                                    .toDouble(), // height of the active requests bar
                            width: 20,
                            color: color, // Color for the current requests bar
                          ),
                          BarChartRodData(
                            fromY:
                                currentRequests
                                    .toDouble(), // Start where the active bar ends
                            toY:
                                totalRequests
                                    .toDouble(), // End at totalRequests
                            width: 20,
                            color:
                                Colors
                                    .grey
                                    .shade300, // Color for the remaining part of the bar
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percentLabel ',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
