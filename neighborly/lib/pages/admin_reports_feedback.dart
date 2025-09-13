import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neighborly/models/feedback_models.dart';

class AdminReportsFeedbackPage extends StatefulWidget {
  const AdminReportsFeedbackPage({super.key});

  @override
  State<AdminReportsFeedbackPage> createState() => _AdminReportsFeedbackPageState();
}

class _AdminReportsFeedbackPageState extends State<AdminReportsFeedbackPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Filters
  String _selectedReportType = 'All';
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _reportTypes = [
    'All',
    'User Behavior',
    'Inappropriate Content',
    'Spam/Scam',
    'Harassment',
    'Technical Issue',
    'Other'
  ];

  final List<String> _statusOptions = [
    'All',
    'pending',
    'investigating',
    'resolved',
    'auto-resolved'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF71BB7B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Report type filter
                Text('Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
                ..._reportTypes.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: _selectedReportType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedReportType = type;
                        });
                      },
                      selectedColor: const Color(0xFF71BB7B).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF71BB7B),
                    ),
                  );
                }),
                const SizedBox(width: 16),
                
                // Status filter
                Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                ..._statusOptions.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status == 'All' ? 'All' : status.capitalize()),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: const Color(0xFF71BB7B).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF71BB7B),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(QueryDocumentSnapshot doc) {
    final report = doc.data() as Map<String, dynamic>;
    final reportData = ReportData.fromJson(report);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(reportData.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(reportData.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(reportData.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reportData.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(reportData.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reportData.severity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(reportData.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.report, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      reportData.reportType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Reported User: ${reportData.reportedUserEmail}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                
                Text(
                  'Reporter: ${reportData.isAnonymous ? "Anonymous" : "User ID: ${reportData.reporterId}"}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  reportData.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Evidence indicators
                if (reportData.textEvidence != null || (reportData.imageEvidenceUrls?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (reportData.textEvidence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.text_fields, size: 12, color: Colors.blue[700]),
                              const SizedBox(width: 4),
                              const Text('Text Evidence', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      if (reportData.imageEvidenceUrls?.isNotEmpty ?? false) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image, size: 12, color: Colors.purple[700]),
                              const SizedBox(width: 4),
                              Text('${reportData.imageEvidenceUrls!.length} Images', 
                                   style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reportData.status == 'pending') ...[
                      TextButton.icon(
                        onPressed: () => _updateReportStatus(doc.id, 'investigating'),
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Investigate'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _updateReportStatus(doc.id, 'resolved'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Resolve'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    if (reportData.status == 'investigating')
                      TextButton.icon(
                        onPressed: () => _updateReportStatus(doc.id, 'resolved'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Resolve'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(QueryDocumentSnapshot doc) {
    final feedback = doc.data() as Map<String, dynamic>;
    final feedbackData = FeedbackData.fromJson(feedback);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF71BB7B).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF71BB7B).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feedbackData.feedbackType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < feedbackData.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(feedbackData.createdAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target User: ${feedbackData.targetUserEmail}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                
                Text(
                  'From: User ID ${feedbackData.userId}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  feedbackData.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                if (feedbackData.improvementSuggestion != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Improvement Suggestion:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedbackData.improvementSuggestion!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      feedbackData.wouldRecommend ? Icons.thumb_up : Icons.thumb_down,
                      size: 16,
                      color: feedbackData.wouldRecommend ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      feedbackData.wouldRecommend ? 'Would Recommend' : 'Would Not Recommend',
                      style: TextStyle(
                        fontSize: 12,
                        color: feedbackData.wouldRecommend ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Mark as read button (if needed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _markFeedbackAsRead(doc.id),
                      icon: const Icon(Icons.mark_email_read, size: 16),
                      label: const Text('Mark as Read'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF71BB7B),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'investigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'auto-resolved':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': newStatus,
        'resolvedAt': newStatus == 'resolved' ? DateTime.now().toIso8601String() : null,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report status updated to $newStatus'),
          backgroundColor: const Color(0xFF71BB7B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markFeedbackAsRead(String feedbackId) async {
    try {
      await FirebaseFirestore.instance
          .collection('feedback')
          .doc(feedbackId)
          .update({
        'read': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback marked as read'),
          backgroundColor: Color(0xFF71BB7B),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking feedback as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Query<Map<String, dynamic>> _getReportsQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);

    if (_selectedReportType != 'All') {
      query = query.where('reportType', isEqualTo: _selectedReportType);
    }

    if (_selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query;
  }

  Query<Map<String, dynamic>> _getFeedbackQuery() {
    return FirebaseFirestore.instance
        .collection('feedback')
        .orderBy('createdAt', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: const Text(
          'Reports & Feedback',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Reports'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Reports Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: _getReportsQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF71BB7B),
                          ),
                        );
                      }

                      var docs = snapshot.data!.docs;
                      
                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final reportedEmail = data['reportedUserEmail']?.toString().toLowerCase() ?? '';
                          return reportedEmail.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.report_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No reports found'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _buildReportCard(docs[index]);
                        },
                      );
                    },
                  ),

                  // Feedback Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: _getFeedbackQuery().snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF71BB7B),
                          ),
                        );
                      }

                      var docs = snapshot.data!.docs;
                      
                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        docs = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final targetEmail = data['targetUserEmail']?.toString().toLowerCase() ?? '';
                          return targetEmail.contains(_searchQuery.toLowerCase());
                        }).toList();
                      }

                      if (docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No feedback found'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          return _buildFeedbackCard(docs[index]);
                        },
                      );
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
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
