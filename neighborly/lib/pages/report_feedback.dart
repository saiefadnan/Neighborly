import 'package:flutter/material.dart';
import 'package:neighborly/models/feedback_models.dart';
import 'package:neighborly/services/report_feedback_service.dart';
import 'package:neighborly/services/image_evidence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:io';

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
  final _reportedUserEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textEvidenceController = TextEditingController();

  String _selectedReportType = 'User Behavior';
  String _selectedSeverity = 'Medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  
  // Image evidence handling
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _selectedImages = [];
  String _evidenceType = 'text'; // 'text' or 'image' or 'both'
  
  // Progress tracking
  bool _isUploadingImages = false;
  double _currentImageProgress = 0.0;
  String _uploadStatus = '';

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
    _reportedUserEmailController.dispose();
    _descriptionController.dispose();
    _textEvidenceController.dispose();
    super.dispose();
  }

  // Enhanced image picker methods with validation
  Future<void> _pickImages() async {
    try {
      if (_selectedImages.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 images allowed per report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        // Check if adding these images would exceed the limit
        final remainingSlots = 5 - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).toList();
        
        if (images.length > remainingSlots) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only added ${imagesToAdd.length} images. Maximum 5 images allowed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Validate each image before adding
        List<File> validImages = [];
        for (XFile xFile in imagesToAdd) {
          final file = File(xFile.path);
          final validation = await ImageEvidenceService.validateImage(file);
          
          if (validation.isValid) {
            validImages.add(file);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid image: ${validation.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validImages);
            if (_evidenceType == 'text') {
              _evidenceType = 'both';
            } else if (_evidenceType != 'both') {
              _evidenceType = 'image';
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (_selectedImages.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 5 images allowed per report'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress slightly for better performance
      );
      
      if (image != null) {
        final file = File(image.path);
        final validation = await ImageEvidenceService.validateImage(file);
        
        if (validation.isValid) {
          setState(() {
            _selectedImages.add(file);
            if (_evidenceType == 'text') {
              _evidenceType = 'both';
            } else if (_evidenceType != 'both') {
              _evidenceType = 'image';
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid image: ${validation.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty && _textEvidenceController.text.isEmpty) {
        _evidenceType = 'text';
      } else if (_selectedImages.isEmpty) {
        _evidenceType = 'text';
      } else if (_textEvidenceController.text.isEmpty) {
        _evidenceType = 'image';
      }
    });
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
      if (_selectedImages.isNotEmpty) {
        _isUploadingImages = true;
        _currentImageProgress = 0.0;
        _uploadStatus = 'Preparing images...';
      }
    });

    try {
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create report data
      final report = ReportData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterId: user.uid,
        reportedUserEmail: _reportedUserEmailController.text.trim(),
        reportType: _selectedReportType,
        severity: _selectedSeverity,
        description: _descriptionController.text.trim(),
        textEvidence:
            _textEvidenceController.text.trim().isEmpty
                ? null
                : _textEvidenceController.text.trim(),
        imageEvidenceUrls: _selectedImages.isNotEmpty 
            ? _selectedImages.map((file) => file.path).toList() 
            : null,
        createdAt: DateTime.now(),
        isAnonymous: _isAnonymous,
      );

      // Submit report to backend with progress tracking
      final result = await ReportFeedbackService.submitReport(
        report, 
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        onImageUploadProgress: (current, total, progress) {
          if (mounted) {
            setState(() {
              _currentImageProgress = progress;
              _uploadStatus = 'Uploading image $current of $total... ${(progress * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
          _uploadStatus = '';
        });

        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
          _uploadStatus = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
    _reportedUserEmailController.clear();
    _descriptionController.clear();
    _textEvidenceController.clear();
    setState(() {
      _selectedReportType = 'User Behavior';
      _selectedSeverity = 'Medium';
      _isAnonymous = false;
      _selectedImages.clear();
      _evidenceType = 'text';
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

            // Reported User Email
            const Text(
              'Reported User Email',
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
                controller: _reportedUserEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter user email address (e.g., user@example.com)',
                  prefixIcon: Icon(
                    Icons.email_outlined,
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
                    return 'Please enter the user\'s email address';
                  }
                  // Basic email validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
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
            
            // Evidence Type Selection
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: const Color(0xFF71BB7B), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Choose Evidence Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Text Evidence Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_evidenceType == 'image') {
                                _evidenceType = 'both';
                              } else if (_evidenceType == 'both') {
                                _evidenceType = 'image';
                              } else {
                                _evidenceType = 'text';
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: (_evidenceType == 'text' || _evidenceType == 'both')
                                  ? const Color(0xFF71BB7B).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_evidenceType == 'text' || _evidenceType == 'both')
                                    ? const Color(0xFF71BB7B)
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.text_fields,
                                  size: 16,
                                  color: (_evidenceType == 'text' || _evidenceType == 'both')
                                      ? const Color(0xFF71BB7B)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Text',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (_evidenceType == 'text' || _evidenceType == 'both')
                                        ? const Color(0xFF71BB7B)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Image Evidence Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_evidenceType == 'text') {
                                _evidenceType = 'both';
                              } else if (_evidenceType == 'both') {
                                _evidenceType = 'text';
                              } else {
                                _evidenceType = 'image';
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: (_evidenceType == 'image' || _evidenceType == 'both')
                                  ? const Color(0xFF71BB7B).withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: (_evidenceType == 'image' || _evidenceType == 'both')
                                    ? const Color(0xFF71BB7B)
                                    : Colors.grey,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 16,
                                  color: (_evidenceType == 'image' || _evidenceType == 'both')
                                      ? const Color(0xFF71BB7B)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Images',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: (_evidenceType == 'image' || _evidenceType == 'both')
                                        ? const Color(0xFF71BB7B)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Text Evidence Input
            if (_evidenceType == 'text' || _evidenceType == 'both')
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
                  controller: _textEvidenceController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the evidence, timestamps, additional context...',
                    prefixIcon: Icon(Icons.description, color: Color(0xFF71BB7B)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            
            if ((_evidenceType == 'text' || _evidenceType == 'both') && (_evidenceType == 'image' || _evidenceType == 'both'))
              const SizedBox(height: 12),

            // Image Evidence Section
            if (_evidenceType == 'image' || _evidenceType == 'both')
              Container(
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
                    // Image picker buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF71BB7B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Selected images display
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected Images:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
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

            // Submit Button with Progress
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  // Progress indicator for image uploads
                  if (_isUploadingImages) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF71BB7B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              LoadingAnimationWidget.staggeredDotsWave(
                                color: const Color(0xFF71BB7B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _uploadStatus,
                                  style: TextStyle(
                                    color: const Color(0xFF71BB7B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: _currentImageProgress,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF71BB7B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Submit button
                  ElevatedButton(
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
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploadingImages 
                                    ? 'Uploading Images...' 
                                    : 'Submitting Report...',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                ],
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
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create feedback data
      final feedback = FeedbackData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        targetUserEmail:
            _userController.text.trim().isEmpty
                ? 'unknown@example.com'
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
        isVerified: true,
      );

      // Submit feedback to backend
      final result = await ReportFeedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

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

            // User Email/Experience (Optional)
            const Text(
              'User Email (Optional)',
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
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'User email address (e.g., helper@example.com)',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Color(0xFF71BB7B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  // Only validate if not empty since this is optional
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
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
