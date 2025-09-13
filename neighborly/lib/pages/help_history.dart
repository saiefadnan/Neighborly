import 'package:flutter/material.dart';
import 'package:neighborly/models/feedback_models.dart';
import 'package:neighborly/pages/report_feedback.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/api_config.dart';

// Custom scrolling text widget for ticker/marquee effect
class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({required this.text, required this.style});

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollingNeeded();
    });
  }

  void _checkIfScrollingNeeded() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent > 0) {
        setState(() {
          _needsScrolling = true;
        });
        _startScrolling();
      }
    }
  }

  void _startScrolling() {
    if (!_needsScrolling || !_scrollController.hasClients) return;

    _animation = Tween<double>(
      begin: 0.0,
      end: _scrollController.position.maxScrollExtent,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animation.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_animation.value);
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _animationController.reset();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _animationController.forward();
              }
            });
          }
        });
      }
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

class HelpHistoryPage extends StatefulWidget {
  const HelpHistoryPage({super.key});

  @override
  State<HelpHistoryPage> createState() => _HelpHistoryPageState();
}

class _HelpHistoryPageState extends State<HelpHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFilter = 'All Time';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Dynamic data from backend
  List<HelpHistory> _helpProvided = [];
  List<HelpHistory> _helpReceived = [];
  bool _isLoading = true;
  String? _error;
  int _userAccumulateXP = 0; // ← ADD THIS LINE

  final List<String> _timeFilters = [
    'All Time',
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];
  final List<String> _statusFilters = [
    'All',
    'Completed',
    'In Progress',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHelpHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch help history from backend with Firestore fallback
  Future<void> _fetchHelpHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchHelpProvided(),
        _fetchHelpReceived(),
        _fetchUserAccumulateXP(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load help history';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHelpProvided() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool success = false;
      List<HelpHistory> providedHelp = [];

      // 1. Try HTTP API first
      try {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/help-history/provided'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            providedHelp =
                (data['data'] as List)
                    .map((item) => HelpHistory.fromBackendJson(item, false))
                    .toList();
            success = true;
            print('Fetched ${providedHelp.length} provided help from API');
          }
        }
      } catch (e) {
        print(
          'API fetch failed for provided help, trying Firestore fallback. Error: $e',
        );
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final helpedRequestsSnapshot =
              await FirebaseFirestore.instance
                  .collection('helpedRequests')
                  .where('acceptedUserID', isEqualTo: user.uid)
                  .get();

          for (var doc in helpedRequestsSnapshot.docs) {
            final helpData = doc.data();

            // Get requester info
            String requesterName = 'Unknown User';
            String requesterImage = 'assets/images/dummy.png';

            if (helpData['requesterId'] != null) {
              try {
                final requesterDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(helpData['requesterId'])
                        .get();

                if (requesterDoc.exists) {
                  final userData = requesterDoc.data()!;
                  requesterName =
                      '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                          .trim();
                  if (requesterName.isEmpty) {
                    requesterName = userData['username'] ?? 'Unknown User';
                  }
                  requesterImage = userData['profilepicurl'] ?? '';
                }
              } catch (e) {
                requesterName = helpData['requesterName'] ?? 'Unknown User';
              }
            }

            final requestData = helpData['originalRequestData'] ?? {};

            providedHelp.add(
              HelpHistory(
                id: doc.id,
                title: requestData['title'] ?? 'Help Request',
                description: requestData['description'] ?? '',
                helpType:
                    requestData['type'] ?? requestData['title'] ?? 'General',
                status: helpData['status'] ?? 'Completed',
                requesterName: requesterName,
                requesterImage: requesterImage,
                location: requestData['address'] ?? 'Unknown location',
                dateCompleted: _parseDate(helpData['completedAt']),
                duration: _calculateDuration(
                  helpData['acceptedAt'],
                  helpData['completedAt'],
                ),
                rating: null, // Will be implemented later
                feedback: null, // Will be implemented later
                helpValuePoints:
                    helpData['xp'] ??
                    _getXPFromPriority(requestData['priority']),
                priority: requestData['priority'] ?? 'normal',
                isReceived: false,
              ),
            );
          }

          success = true;
          print('Fetched ${providedHelp.length} provided help from Firestore');
        } catch (e) {
          print('Firestore fallback failed for provided help: $e');
        }
      }

      setState(() {
        _helpProvided = providedHelp;
      });
    } catch (e) {
      print('Error fetching provided help: $e');
    }
  }

  Future<void> _fetchHelpReceived() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool success = false;
      List<HelpHistory> receivedHelp = [];

      // 1. Try HTTP API first
      try {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/help-history/received'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            receivedHelp =
                (data['data'] as List)
                    .map((item) => HelpHistory.fromBackendJson(item, true))
                    .toList();
            success = true;
            print('Fetched ${receivedHelp.length} received help from API');
          }
        }
      } catch (e) {
        print(
          'API fetch failed for received help, trying Firestore fallback. Error: $e',
        );
      }

      // 2. Firestore fallback if API failed
      if (!success) {
        try {
          final helpedRequestsSnapshot =
              await FirebaseFirestore.instance
                  .collection('helpedRequests')
                  .where('requesterId', isEqualTo: user.uid)
                  .get();

          for (var doc in helpedRequestsSnapshot.docs) {
            final helpData = doc.data();

            // Get helper info
            String helperName = 'Unknown Helper';
            String helperImage = 'assets/images/dummy.png';

            if (helpData['acceptedUserID'] != null) {
              try {
                final helperDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(helpData['acceptedUserID'])
                        .get();

                if (helperDoc.exists) {
                  final userData = helperDoc.data()!;
                  helperName =
                      '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
                          .trim();
                  if (helperName.isEmpty) {
                    helperName = userData['username'] ?? 'Unknown Helper';
                  }
                  helperImage = userData['profilepicurl'] ?? '';
                }
              } catch (e) {
                helperName =
                    helpData['responderName'] ??
                    helpData['initiatorName'] ??
                    'Unknown Helper';
              }
            }

            final requestData = helpData['originalRequestData'] ?? {};

            receivedHelp.add(
              HelpHistory(
                id: doc.id,
                title: requestData['title'] ?? 'Help Request',
                description: requestData['description'] ?? '',
                helpType:
                    requestData['type'] ?? requestData['title'] ?? 'General',
                status: helpData['status'] ?? 'Completed',
                requesterName: 'You', // Current user
                requesterImage: 'assets/images/dummy.png',
                helperName: helperName,
                helperImage: helperImage,
                location: requestData['address'] ?? 'Unknown location',
                dateCompleted: _parseDate(helpData['completedAt']),
                duration: _calculateDuration(
                  helpData['acceptedAt'],
                  helpData['completedAt'],
                ),
                rating: null, // Will be implemented later
                feedback: null, // Will be implemented later
                helpValuePoints: 0, // Receivers don't get XP
                priority: requestData['priority'] ?? 'normal',
                isReceived: true,
              ),
            );
          }

          success = true;
          print('Fetched ${receivedHelp.length} received help from Firestore');
        } catch (e) {
          print('Firestore fallback failed for received help: $e');
        }
      }

      setState(() {
        _helpReceived = receivedHelp;
      });
    } catch (e) {
      print('Error fetching received help: $e');
    }
  }

  Future<void> _fetchUserAccumulateXP() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      bool success = false;
      int accumulateXP = 0;

      // 1. Try HTTP API first (using existing profile API)
      try {
        final token = await user.getIdToken();
        final response = await http.get(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/gamification/user/xp',
          ), // ← CHANGED API
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('FULL API RESPONSE: $data'); // ← ADD THIS DEBUG LINE
          if (data['success'] == true) {
            print('XP API DATA FIELDS: ${data['data'].keys}');
            accumulateXP = data['data']['accumulateXP'] ?? 0;
            success = true;
            print('Fetched accumulate XP from gamification API: $accumulateXP');
          }
        }
      } catch (e) {
        print(
          'API fetch failed for accumulate XP, trying Firestore fallback. Error: $e',
        );
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
            accumulateXP = userData['accumulateXP'] ?? 0;
            success = true;
            print('Fetched accumulate XP from Firestore: $accumulateXP');
          }
        } catch (e) {
          print('Firestore fallback failed for accumulate XP: $e');
        }
      }

      setState(() {
        _userAccumulateXP = accumulateXP;
      });
    } catch (e) {
      print('Error fetching user accumulate XP: $e');
    }
  }

  // Helper functions
  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();

    if (date is Timestamp) {
      return date.toDate();
    } else if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  String _calculateDuration(dynamic startDate, dynamic endDate) {
    try {
      final start = _parseDate(startDate);
      final end = _parseDate(endDate);
      final duration = end.difference(start);

      if (duration.inDays > 0) {
        return '${duration.inDays} days';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} hours ${duration.inMinutes % 60} minutes';
      } else {
        return '${duration.inMinutes} minutes';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  int _getXPFromPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'emergency':
        return 500;
      case 'urgent':
        return 300;
      default:
        return 100;
    }
  }

  // Get XP color based on value
  Color _getXPColor(int xp) {
    if (xp >= 500) {
      return const Color(0xFFFFD700); // Gold
    } else if (xp >= 300) {
      return const Color(0xFFC0C0C0); // Silver
    } else {
      return const Color(0xFFCD7F32); // Bronze
    }
  }

  IconData _getXPIcon(int xp) {
    if (xp >= 500) {
      return Icons.emoji_events; // Trophy for gold
    } else if (xp >= 300) {
      return Icons.military_tech; // Medal for silver
    } else {
      return Icons.stars; // Stars for bronze
    }
  }

  List<HelpHistory> _getFilteredHistory(List<HelpHistory> history) {
    return history.where((help) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          help.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          help.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (help.helperName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          help.requesterName.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus =
          _selectedStatusFilter == 'All' ||
          help.status == _selectedStatusFilter;

      bool matchesTime = true;
      if (_selectedTimeFilter != 'All Time') {
        DateTime now = DateTime.now();
        DateTime filterDate;
        switch (_selectedTimeFilter) {
          case 'This Week':
            filterDate = now.subtract(Duration(days: 7));
            break;
          case 'This Month':
            filterDate = now.subtract(Duration(days: 30));
            break;
          case 'Last 3 Months':
            filterDate = now.subtract(Duration(days: 90));
            break;
          case 'This Year':
            filterDate = now.subtract(Duration(days: 365));
            break;
          default:
            filterDate = DateTime(2000);
        }
        matchesTime = help.dateCompleted.isAfter(filterDate);
      }

      return matchesSearch && matchesStatus && matchesTime;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getHelpTypeIcon(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Icons.local_hospital;
      case 'Grocery':
      case 'Groceries':
        return Icons.shopping_cart;
      case 'Shifting Furniture':
        return Icons.chair;
      case 'Route':
        return Icons.directions;
      case 'Pet Care':
        return Icons.pets;
      case 'Education':
        return Icons.school;
      case 'Repair':
        return Icons.build;
      case 'Emergency':
        return Icons.emergency;
      case 'Transport':
        return Icons.directions_car;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search help history...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF71BB7B),
                  size: 20,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 18,
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Row
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Time', _selectedTimeFilter, _timeFilters, (
                    value,
                  ) {
                    setState(() {
                      _selectedTimeFilter = value;
                    });
                  }),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    'Status',
                    _selectedStatusFilter,
                    _statusFilters,
                    (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder:
          (context) =>
              options
                  .map(
                    (option) =>
                        PopupMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selectedValue != options.first
                  ? const Color(0xFF71BB7B)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                color:
                    selectedValue != options.first
                        ? Colors.white
                        : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color:
                  selectedValue != options.first
                      ? Colors.white
                      : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTrustInfo(HelpHistory help) {
    final String userId =
        help.isReceived ? (help.helperName ?? 'helper') : help.requesterName;
    final double avgRating = FeedbackService.getAverageRating(userId);
    final int feedbackCount = FeedbackService.getFeedbackCount(userId);
    final double trustScore = FeedbackService.getTrustScore(userId);

    if (feedbackCount == 0) {
      return Row(
        children: [
          Icon(Icons.fiber_new, size: 12, color: Colors.orange[600]),
          const SizedBox(width: 4),
          Text(
            'New User',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < avgRating ? Icons.star : Icons.star_border,
              size: 10,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(width: 4),
        Text(
          avgRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($feedbackCount)',
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _getTrustColor(trustScore),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 8, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                '${trustScore.toInt()}%',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTrustColor(double trustScore) {
    if (trustScore >= 90) return Colors.green;
    if (trustScore >= 75) return const Color(0xFF71BB7B);
    if (trustScore >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHistoryCard(HelpHistory help) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showHistoryDetails(help),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        help.isReceived && help.helperImage != null
                            ? (help.helperImage!.isNotEmpty
                                ? Image.network(
                                  help.helperImage!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                            'assets/images/dummy.png',
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                )
                                : Image.asset(
                                  'assets/images/dummy.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ))
                            : (help.requesterImage.isNotEmpty
                                ? Image.network(
                                  help.requesterImage,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                            'assets/images/dummy.png',
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          ),
                                )
                                : Image.asset(
                                  'assets/images/dummy.png',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )),
                  ),
                  const SizedBox(width: 12),

                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          help.isReceived
                              ? (help.helperName ?? 'Helper')
                              : help.requesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              help.isReceived
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 14,
                              color:
                                  help.isReceived ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              help.isReceived
                                  ? 'Help Received'
                                  : 'Help Provided',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    help.isReceived
                                        ? Colors.blue
                                        : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildUserTrustInfo(help),
                      ],
                    ),
                  ),

                  // Status and Date Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(help.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          help.status,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(help.dateCompleted),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Help Type and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getHelpTypeIcon(help.helpType),
                          size: 14,
                          color: const Color(0xFF71BB7B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          help.helpType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF71BB7B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                help.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                help.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom Row with stats
              Row(
                children: [
                  if (help.rating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${help.rating}/5',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  if (help.helpValuePoints > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getXPColor(
                          help.helpValuePoints,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getXPIcon(help.helpValuePoints),
                            size: 12,
                            color: _getXPColor(help.helpValuePoints),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${help.helpValuePoints} pts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getXPColor(help.helpValuePoints),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  _buildScrollingTimeContainer(help.duration),
                  const SizedBox(width: 6),

                  _buildActionButton(
                    'Details',
                    Icons.info_outline,
                    Colors.grey[700]!,
                    () => _showHistoryDetails(help),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollingTimeContainer(String duration) {
    return Container(
      width: 90,
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Expanded(
            child: Center(
              child: _ScrollingText(
                text: duration,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetails(HelpHistory help) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          help.isReceived && help.helperImage != null
                              ? (help.helperImage!.isNotEmpty
                                  ? Image.network(
                                    help.helperImage!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/dummy.png',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                  : Image.asset(
                                    'assets/images/dummy.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ))
                              : (help.requesterImage.isNotEmpty
                                  ? Image.network(
                                    help.requesterImage,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'assets/images/dummy.png',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                  )
                                  : Image.asset(
                                    'assets/images/dummy.png',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            help.isReceived
                                ? (help.helperName ?? 'Helper')
                                : help.requesterName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                help.isReceived
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 16,
                                color:
                                    help.isReceived
                                        ? Colors.blue
                                        : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                help.isReceived
                                    ? 'Help Received'
                                    : 'Help Provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      help.isReceived
                                          ? Colors.blue
                                          : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(help.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        help.status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Help Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHelpTypeIcon(help.helpType),
                        size: 18,
                        color: const Color(0xFF71BB7B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        help.helpType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71BB7B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  help.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  help.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location: ${help.location}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Duration: ${help.duration}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Date: ${_formatFullDate(help.dateCompleted)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rating and Points (if completed)
                if (help.status == 'Completed') ...[
                  Row(
                    children: [
                      if (help.rating != null) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 32,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${help.rating}/5',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Rating',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      if (help.helpValuePoints > 0) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getXPColor(
                                help.helpValuePoints,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getXPIcon(help.helpValuePoints),
                                  size: 32,
                                  color: _getXPColor(help.helpValuePoints),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+${help.helpValuePoints}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getXPColor(help.helpValuePoints),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Feedback (if available)
                if (help.feedback != null) ...[
                  Text(
                    'Feedback:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF71BB7B).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      help.feedback!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons based on status
                if (help.status == 'In Progress') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.update),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF71BB7B),
                            side: const BorderSide(color: Color(0xFF71BB7B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (help.status == 'Completed') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ReportFeedbackPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Leave Feedback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF71BB7B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ReportFeedbackPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.report_outlined),
                          label: const Text('Report Issue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStatsOverview() {
    final completedProvided = _helpProvided.length; // All fetched are completed
    final completedReceived = _helpReceived.length; // All fetched are completed
    final avgRating =
        _helpProvided.where((h) => h.rating != null).isEmpty
            ? 0.0
            : _helpProvided
                    .where((h) => h.rating != null)
                    .fold(0.0, (sum, h) => sum + h.rating!) /
                _helpProvided.where((h) => h.rating != null).length;
    _helpProvided.where((h) => h.rating != null).isEmpty
        ? 0.0
        : _helpProvided
                .where((h) => h.rating != null)
                .fold(0.0, (sum, h) => sum + h.rating!) /
            _helpProvided.where((h) => h.rating != null).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF71BB7B), const Color(0xFF5EA968)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF71BB7B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'My Help Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Provided',
                  _helpProvided.length.toString(), // Direct count from backend
                  Icons.volunteer_activism,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Received',
                  _helpReceived.length.toString(), // Direct count from backend
                  Icons.help_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Points',
                  _userAccumulateXP.toString(),
                  Icons.emoji_events,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  avgRating.isNaN ? '0.0' : avgRating.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F2E7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF71BB7B),
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.history, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Help History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF71BB7B)),
              SizedBox(height: 16),
              Text(
                'Loading help history...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F2E7),
        appBar: AppBar(
          backgroundColor: const Color(0xFF71BB7B),
          elevation: 0,
          title: const Row(
            children: [
              Icon(Icons.history, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Help History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchHelpHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Help History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism),
                  const SizedBox(width: 8),
                  Text(
                    'Provided (${_getFilteredHistory(_helpProvided).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Received (${_getFilteredHistory(_helpReceived).length})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScrollableHistoryView(_helpProvided, true),
          _buildScrollableHistoryView(_helpReceived, false),
        ],
      ),
    );
  }

  Widget _buildScrollableHistoryView(
    List<HelpHistory> history,
    bool isProvided,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildStatsOverview()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            minHeight: 120,
            maxHeight: 120,
            child: _buildFilterSection(),
          ),
        ),
        _buildSliverHistoryList(history, isProvided),
      ],
    );
  }

  Widget _buildSliverHistoryList(List<HelpHistory> history, bool isProvided) {
    final filteredHistory = _getFilteredHistory(history);

    if (filteredHistory.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProvided ? Icons.volunteer_activism : Icons.help_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isProvided ? 'No help provided yet' : 'No help received yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProvided
                    ? 'Start helping your neighbors to build your contribution history'
                    : 'Request help from your community when you need it',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildHistoryCard(filteredHistory[index]),
        childCount: filteredHistory.length,
      ),
    );
  }
}

// Custom delegate for sticky header behavior
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class HelpHistory {
  final String id;
  final String title;
  final String description;
  final String helpType;
  final String status;
  final String requesterName;
  final String requesterImage;
  final String? helperName;
  final String? helperImage;
  final String location;
  final DateTime dateCompleted;
  final String duration;
  final int? rating;
  final String? feedback;
  final int helpValuePoints;
  final String priority;
  final bool isReceived;

  HelpHistory({
    required this.id,
    required this.title,
    required this.description,
    required this.helpType,
    required this.status,
    required this.requesterName,
    required this.requesterImage,
    this.helperName,
    this.helperImage,
    required this.location,
    required this.dateCompleted,
    required this.duration,
    this.rating,
    this.feedback,
    required this.helpValuePoints,
    required this.priority,
    this.isReceived = false,
  });

  // Factory method to create HelpHistory from backend JSON
  factory HelpHistory.fromBackendJson(
    Map<String, dynamic> json,
    bool isReceived,
  ) {
    return HelpHistory(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Help Request',
      description: json['description'] ?? '',
      helpType: json['type'] ?? 'General',
      status: json['status'] ?? 'Completed',
      requesterName:
          isReceived ? 'You' : (json['requester']?['name'] ?? 'Unknown User'),
      requesterImage:
          isReceived ? '' : (json['requester']?['profilePicture'] ?? ''),
      helperName: isReceived ? (json['helper']?['name'] ?? 'Helper') : null,
      helperImage:
          isReceived ? (json['helper']?['profilePicture'] ?? '') : null,
      location: json['location'] ?? 'Unknown location',
      dateCompleted:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      duration: _calculateDurationFromJson(
        json['acceptedAt'],
        json['completedAt'],
      ),
      rating: json['rating'],
      feedback: json['feedback'],
      helpValuePoints: json['xp'] ?? 0,
      priority: json['priority'] ?? 'normal',
      isReceived: isReceived,
    );
  }

  static String _calculateDurationFromJson(String? startDate, String? endDate) {
    try {
      if (startDate == null || endDate == null) return 'Unknown';

      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final duration = end.difference(start);

      if (duration.inDays > 0) {
        return '${duration.inDays} days';
      } else if (duration.inHours > 0) {
        return '${duration.inHours} hours ${duration.inMinutes % 60} minutes';
      } else {
        return '${duration.inMinutes} minutes';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
