import 'package:flutter/material.dart';
import 'package:neighborly/models/feedback_models.dart';

class ReportFeedbackPage extends StatefulWidget {
  const ReportFeedbackPage({super.key});

  @override
  State<ReportFeedbackPage> createState() => _ReportFeedbackPageState();
}

class _ReportFeedbackPageState extends State<ReportFeedbackPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.feedback_outlined, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Report & Feedback',
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
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_outlined),
                  SizedBox(width: 8),
                  Text('Report Issue'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined),
                  SizedBox(width: 8),
                  Text('Leave Feedback'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ReportTab(), FeedbackTab()],
      ),
    );
  }
}

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  final _formKey = GlobalKey<FormState>();
  final _reportedUserController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _evidenceController = TextEditingController();

  String _selectedReportType = 'User Behavior';
  String _selectedSeverity = 'Medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  final List<String> _reportTypes = [
    'User Behavior',
    'Inappropriate Content',
    'Spam/Scam',
    'Harassment',
    'Safety Concern',
    'Fake Profile',
    'Service Quality',
    'Payment Issue',
    'Other',
  ];

  final List<String> _severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _reportedUserController.dispose();
    _descriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.blue;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      case 'Critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getReportTypeIcon(String type) {
    switch (type) {
      case 'User Behavior':
        return Icons.person_off;
      case 'Inappropriate Content':
        return Icons.block;
      case 'Spam/Scam':
        return Icons.security;
      case 'Harassment':
        return Icons.warning;
      case 'Safety Concern':
        return Icons.shield;
      case 'Fake Profile':
        return Icons.person_remove;
      case 'Service Quality':
        return Icons.thumb_down;
      case 'Payment Issue':
        return Icons.payment;
      default:
        return Icons.report;
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create report data
      final report = ReportData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterId: 'current_user_id', // In real app, get from auth
        reportedUserId: _reportedUserController.text.trim(),
        reportType: _selectedReportType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        evidence:
            _evidenceController.text.trim().isEmpty
                ? null
                : _evidenceController.text.trim(),
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
      );

      // Save report
      FeedbackService.addReport(report);

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show error dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF71BB7B),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Report Submitted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Thank you for your report. Our team will review it within 24-48 hours and take appropriate action.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
    );
  }

  void _resetForm() {
    _reportedUserController.clear();
    _descriptionController.clear();
    _evidenceController.clear();
    setState(() {
      _selectedReportType = 'User Behavior';
      _selectedSeverity = 'Medium';
      _isAnonymous = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF71BB7B).withOpacity(0.1),
                    const Color(0xFF5EA968).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF71BB7B).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: const Color(0xFF71BB7B),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help Us Keep Neighborly Safe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Report any issues or concerns to help maintain a safe and trustworthy community.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Type Selection
            const Text(
              'Report Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    _getReportTypeIcon(_selectedReportType),
                    color: const Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items:
                    _reportTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            
                            const SizedBox(width: 12),
                            Text(type),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedReportType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Severity Level
            const Text(
              'Severity Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _severityLevels.map((severity) {
                      final isSelected = _selectedSeverity == severity;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSeverity = severity;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? _getSeverityColor(severity)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getSeverityColor(severity),
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: _getSeverityColor(
                                          severity,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : _getSeverityColor(severity),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Reported User/Content
            const Text(
              'Reported User/Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _reportedUserController,
                decoration: const InputDecoration(
                  hintText: 'Enter username, help request ID, or content',
                  prefixIcon: Icon(
                    Icons.person_search,
                    color: Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please specify what you\'re reporting';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Please provide detailed information about the issue...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.trim().length < 10) {
                    return 'Please provide more details (minimum 10 characters)';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Evidence/Additional Info
            const Text(
              'Evidence/Additional Information (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _evidenceController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Screenshots, timestamps, additional context...',
                  prefixIcon: Icon(Icons.attach_file, color: Color(0xFF71BB7B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Anonymous Option
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    color: const Color(0xFF71BB7B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submit Anonymously',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'Your identity will not be shared with the reported user',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                    activeColor: const Color(0xFF71BB7B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Submit Report',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'False reports may result in account suspension. Please ensure your report is accurate and follows community guidelines.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        height: 1.3,
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
  }
}

class FeedbackTab extends StatefulWidget {
  const FeedbackTab({super.key});

  @override
  State<FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<FeedbackTab> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _feedbackController = TextEditingController();
  final _improvementController = TextEditingController();

  String _selectedFeedbackType = 'Help Experience';
  double _rating = 5.0;
  bool _wouldRecommend = true;
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'Help Experience',
    'App Features',
    'User Interface',
    'Community Interaction',
    'Safety & Trust',
    'Performance',
    'Suggestion',
    'Other',
  ];

  @override
  void dispose() {
    _userController.dispose();
    _feedbackController.dispose();
    _improvementController.dispose();
    super.dispose();
  }

  IconData _getFeedbackTypeIcon(String type) {
    switch (type) {
      case 'Help Experience':
        return Icons.volunteer_activism;
      case 'App Features':
        return Icons.featured_play_list;
      case 'User Interface':
        return Icons.design_services;
      case 'Community Interaction':
        return Icons.people;
      case 'Safety & Trust':
        return Icons.shield;
      case 'Performance':
        return Icons.speed;
      case 'Suggestion':
        return Icons.lightbulb;
      default:
        return Icons.feedback;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create feedback data
      final feedback = FeedbackData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // In real app, get from auth
        targetUserId:
            _userController.text.trim().isEmpty
                ? 'unknown_user'
                : _userController.text.trim(),
        feedbackType: _selectedFeedbackType,
        rating: _rating,
        description: _feedbackController.text.trim(),
        improvementSuggestion:
            _improvementController.text.trim().isEmpty
                ? null
                : _improvementController.text.trim(),
        wouldRecommend: _wouldRecommend,
        createdAt: DateTime.now(),
        isVerified: true, // Mark as verified since it's from current user
      );

      // Save feedback
      FeedbackService.addFeedback(feedback);

      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show error dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.thumb_up_outlined,
                    color: Color(0xFF71BB7B),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Feedback Submitted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Thank you for your valuable feedback! It helps us improve Neighborly for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
    );
  }

  void _resetForm() {
    _userController.clear();
    _feedbackController.clear();
    _improvementController.clear();
    setState(() {
      _selectedFeedbackType = 'Help Experience';
      _rating = 5.0;
      _wouldRecommend = true;
    });
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF71BB7B).withOpacity(0.1),
                    const Color(0xFF5EA968).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF71BB7B).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    color: const Color(0xFF71BB7B),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share Your Experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your feedback helps build a better community for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Overall Rating
            const Text(
              'Overall Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
              child: Column(
                children: [
                  _buildStarRating(),
                  const SizedBox(height: 8),
                  Text(
                    '${_rating.toInt()}/5 Stars',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Feedback Type
            const Text(
              'Feedback Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: DropdownButtonFormField<String>(
                value: _selectedFeedbackType,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    _getFeedbackTypeIcon(_selectedFeedbackType),
                    color: const Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items:
                    _feedbackTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            
                            const SizedBox(width: 12),
                            Text(type),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFeedbackType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // User/Experience (Optional)
            const Text(
              'About User/Experience (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  hintText: 'Username or help request details...',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Detailed Feedback
            const Text(
              'Your Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Share your experience, what went well, what could be improved...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide your feedback';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Improvement Suggestions
            const Text(
              'Suggestions for Improvement (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
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
              child: TextFormField(
                controller: _improvementController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Any ideas to make Neighborly better?',
                  prefixIcon: Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
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
              child: Row(
                children: [
                  Icon(
                    Icons.recommend,
                    color: const Color(0xFF71BB7B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Would you recommend Neighborly?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'Help others discover our community',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _wouldRecommend,
                    onChanged: (value) {
                      setState(() {
                        _wouldRecommend = value;
                      });
                    },
                    activeColor: const Color(0xFF71BB7B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF71BB7B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Submit Feedback',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // Thank you note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF71BB7B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF71BB7B).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.favorite,
                    color: const Color(0xFF71BB7B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your feedback is valuable and helps us create a better experience for the entire Neighborly community.',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF71BB7B),
                        height: 1.3,
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
  }
}
