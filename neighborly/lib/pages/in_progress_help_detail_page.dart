import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neighborly/models/help_chat_models.dart';
import 'package:neighborly/services/help_chat_service.dart';
import 'package:neighborly/pages/help_chat_page.dart';
import 'package:neighborly/pages/help_progress_tracker.dart';
import 'package:neighborly/pages/completion_confirmation_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class InProgressHelpDetailPage extends StatefulWidget {
  final String helpRequestId;
  final Map<String, dynamic> helpRequestData;

  const InProgressHelpDetailPage({
    super.key,
    required this.helpRequestId,
    required this.helpRequestData,
  });

  @override
  State<InProgressHelpDetailPage> createState() => _InProgressHelpDetailPageState();
}

class _InProgressHelpDetailPageState extends State<InProgressHelpDetailPage> {
  final HelpChatService _chatService = HelpChatService();
  
  String? _currentUserId;
  bool _isRequester = false;
  String _otherPartyName = '';
  String _otherPartyId = '';
  HelpCompletionRequest? _completionRequest;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _checkForCompletionRequest();
  }

  void _initializeUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      
      final requesterId = widget.helpRequestData['requesterId'] as String;
      final responderId = widget.helpRequestData['responderId'] as String;
      
      _isRequester = _currentUserId == requesterId;
      
      if (_isRequester) {
        _otherPartyId = responderId;
        _otherPartyName = widget.helpRequestData['responderName'] as String? ?? 'Helper';
      } else {
        _otherPartyId = requesterId;
        _otherPartyName = widget.helpRequestData['requesterName'] as String? ?? 'Requester';
      }
      
      setState(() {});
    }
  }

  void _checkForCompletionRequest() async {
    try {
      final completionRequest = await _chatService.getCompletionRequest(widget.helpRequestId);
      if (mounted) {
        setState(() {
          _completionRequest = completionRequest;
        });
      }
    } catch (e) {
      print('Error checking completion request: $e');
    }
  }

  void _navigateToChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpChatPage(
          helpRequestId: widget.helpRequestId,
          helpRequestTitle: widget.helpRequestData['title'] as String? ?? 'Help Request',
          otherPartyName: _otherPartyName,
          otherPartyId: _otherPartyId,
          isRequester: _isRequester,
        ),
      ),
    );
  }

  void _navigateToProgress() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpProgressTracker(
          helpRequestId: widget.helpRequestId,
          helpRequestTitle: widget.helpRequestData['title'] as String? ?? 'Help Request',
          isRequester: _isRequester,
        ),
      ),
    );
  }

  void _handleCompletionRequest() {
    if (_completionRequest != null) {
      // Navigate to confirmation page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CompletionConfirmationPage(
            helpRequestId: widget.helpRequestId,
            helpRequestTitle: widget.helpRequestData['title'] as String? ?? 'Help Request',
            completionRequest: _completionRequest!,
          ),
        ),
      ).then((_) {
        // Refresh completion request status when returning
        _checkForCompletionRequest();
      });
    }
  }

  Widget _buildStatusBanner() {
    if (_completionRequest?.status == HelpCompletionStatus.pending) {
      final isPendingForMe = _completionRequest!.initiatorId != _currentUserId;
      
      if (isPendingForMe) {
        return GestureDetector(
          onTap: _handleCompletionRequest,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[400]!, Colors.amber[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notification_important,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completion Request Pending',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_completionRequest!.initiatorName} wants to mark this as complete',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.blue[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waiting for Confirmation',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'You\'ve requested completion. Waiting for ${_otherPartyName} to confirm.',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
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
    
    return const SizedBox.shrink();
  }

  Widget _buildHelpRequestInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF71BB7B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'IN PROGRESS',
                style: TextStyle(
                  color: Color(0xFF71BB7B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                timeago.format(
                  (widget.helpRequestData['acceptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.helpRequestData['title'] as String? ?? 'Help Request',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.helpRequestData['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.helpRequestData['description'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPartyInfo(
                'Requester',
                widget.helpRequestData['requesterName'] as String? ?? 'Unknown',
                Icons.person,
                _isRequester,
              ),
              const SizedBox(width: 16),
              _buildPartyInfo(
                'Helper',
                widget.helpRequestData['responderName'] as String? ?? 'Unknown',
                Icons.volunteer_activism,
                !_isRequester,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartyInfo(String role, String name, IconData icon, bool isCurrentUser) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser 
              ? const Color(0xFF71BB7B).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: isCurrentUser 
              ? Border.all(color: const Color(0xFF71BB7B).withOpacity(0.3))
              : Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isCurrentUser ? const Color(0xFF71BB7B) : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? const Color(0xFF71BB7B) : Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isCurrentUser) ...[
              const SizedBox(height: 2),
              Text(
                '(You)',
                style: TextStyle(
                  fontSize: 10,
                  color: const Color(0xFF71BB7B).withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chat button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _navigateToChat,
              icon: const Icon(Icons.chat_bubble, size: 20),
              label: const Text(
                'Open Chat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF71BB7B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Progress tracker button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _navigateToProgress,
              icon: const Icon(Icons.timeline, size: 20),
              label: const Text(
                'View Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF71BB7B),
                side: const BorderSide(color: Color(0xFF71BB7B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: const Text(
          'Help in Progress',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner (completion request notification)
            _buildStatusBanner(),
            
            const SizedBox(height: 8),
            
            // Help request info
            _buildHelpRequestInfo(),
            
            const SizedBox(height: 24),
            
            // Action buttons
            _buildActionButtons(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
