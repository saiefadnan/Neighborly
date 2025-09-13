import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighborly/models/help_chat_models.dart';
import 'package:neighborly/services/help_chat_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class HelpChatPage extends StatefulWidget {
  final String helpRequestId;
  final String helpRequestTitle;
  final String otherPartyName;
  final String otherPartyId;
  final bool isRequester; // true if current user is the requester, false if responder

  const HelpChatPage({
    super.key,
    required this.helpRequestId,
    required this.helpRequestTitle,
    required this.otherPartyName,
    required this.otherPartyId,
    required this.isRequester,
  });

  @override
  State<HelpChatPage> createState() => _HelpChatPageState();
}

class _HelpChatPageState extends State<HelpChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final HelpChatService _chatService = HelpChatService();
  
  String? _currentUserId;
  String? _currentUserName;
  bool _isLoading = false;
  bool _isSending = false;
  
  // Completion timer state
  bool _isCompleted = false;
  int _remainingSeconds = 60;
  Timer? _deletionTimer;
  bool _hasPendingCompletionRequest = false;
  Set<String> _respondedCompletionRequests = <String>{}; // Track responded completion requests

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _markMessagesAsRead();
    _listenToCompletionStatus();
  }

  void _initializeUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous';
      });
    }
  }

  void _markMessagesAsRead() async {
    if (_currentUserId != null) {
      await _chatService.markMessagesAsRead(widget.helpRequestId, _currentUserId!);
    }
  }

  void _listenToCompletionStatus() {
    // Listen for changes in help request status (in case someone completes it from confirmation page)
    FirebaseFirestore.instance
        .collection('helpedRequests')
        .doc(widget.helpRequestId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        final status = data?['status'] as String?;
        
        if (status == 'completed' && !_isCompleted) {
          // Help was completed from elsewhere (confirmation page), start countdown
          _startDeletionCountdown();
          // Also clear any pending completion request
          setState(() {
            _hasPendingCompletionRequest = false;
          });
        }
      }
    });

    // Listen for pending completion requests with real-time updates
    FirebaseFirestore.instance
        .collection('helpCompletionRequests')
        .where('helpRequestId', isEqualTo: widget.helpRequestId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _hasPendingCompletionRequest = snapshot.docs.isNotEmpty;
          print('DEBUG: Updated pending status from listener: $_hasPendingCompletionRequest');
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _deletionTimer?.cancel(); // Clean up timer
    super.dispose();
  }

  void _scrollToBottom() {
    // Don't auto-scroll during countdown to prevent UI jumping
    if (_scrollController.hasClients && !_isCompleted) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final result = await _chatService.sendMessage(
        helpRequestId: widget.helpRequestId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        message: messageText,
        type: HelpChatMessageType.text,
      );

      if (result['success'] == true) {
        _scrollToBottom();
      } else {
        _showErrorSnackBar('Failed to send message: ${result['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _sendProgressUpdate(HelpProgressStatus status, String message) async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Send progress update
      await _chatService.sendProgressUpdate(
        helpRequestId: widget.helpRequestId,
        updaterId: _currentUserId!,
        updaterName: _currentUserName!,
        status: status,
        message: message,
      );

      // Send chat message about the progress update
      await _chatService.sendMessage(
        helpRequestId: widget.helpRequestId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        message: '📍 $message',
        type: HelpChatMessageType.progressUpdate,
        metadata: {'progressStatus': status.toString().split('.').last},
      );

      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Error updating progress: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestCompletion() async {
    if (_currentUserId == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CompletionRequestDialog(),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _chatService.requestCompletion(
          helpRequestId: widget.helpRequestId,
          initiatorId: _currentUserId!,
          initiatorName: _currentUserName!,
          initiatorType: widget.isRequester 
              ? HelpCompletionInitiator.requester 
              : HelpCompletionInitiator.responder,
          message: result,
        );

        // Send chat message about completion request
        await _chatService.sendMessage(
          helpRequestId: widget.helpRequestId,
          senderId: _currentUserId!,
          senderName: _currentUserName!,
          message: '✅ Requested help completion: $result',
          type: HelpChatMessageType.completionRequest,
        );

        _scrollToBottom();
        _showSuccessSnackBar('Completion request sent!');
        
        // Update state to show that completion request is now pending
        setState(() {
          _hasPendingCompletionRequest = true;
        });
      } catch (e) {
        _showErrorSnackBar('Error requesting completion: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF71BB7B),
      ),
    );
  }

  Future<void> _handleCompletionResponse(HelpChatMessage message, bool approved, String requestKey) async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Confirm the completion using the chat service
      await _chatService.confirmCompletion(
        helpRequestId: widget.helpRequestId,
        confirmerId: _currentUserId!,
        confirmerName: _currentUserName!,
        approved: approved,
        feedback: null, // No feedback in quick chat response
      );

      // Send a follow-up chat message about the response
      final responseMessage = approved 
          ? '✅ Completion accepted! Help is now marked as complete.'
          : '❌ Completion declined. More work is needed.';
      
      await _chatService.sendMessage(
        helpRequestId: widget.helpRequestId,
        senderId: _currentUserId!,
        senderName: _currentUserName!,
        message: responseMessage,
        type: HelpChatMessageType.system,
      );

      _scrollToBottom();
      _showSuccessSnackBar(approved 
          ? 'Completion accepted! 🎉' 
          : 'Completion declined');

      // Start deletion countdown if completion was approved
      if (approved) {
        _startDeletionCountdown();
      }

      // Mark this completion request as responded
      setState(() {
        _respondedCompletionRequests.add(requestKey);
        _hasPendingCompletionRequest = false;
        print('DEBUG: Marked completion request as responded: $requestKey');
        print('DEBUG: Cleared pending completion request, approved: $approved');
      });

    } catch (e) {
      _showErrorSnackBar('Error responding to completion: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageBubble(HelpChatMessage message) {
    final isMe = message.senderId == _currentUserId;
    final isSystemMessage = message.type == HelpChatMessageType.system ||
                           message.type == HelpChatMessageType.progressUpdate ||
                           message.type == HelpChatMessageType.completionRequest;

    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF71BB7B) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey[500],
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMessage(HelpChatMessage message) {
    IconData icon;
    Color color;
    
    switch (message.type) {
      case HelpChatMessageType.progressUpdate:
        icon = Icons.location_on;
        color = Colors.blue;
        break;
      case HelpChatMessageType.completionRequest:
        icon = Icons.check_circle;
        color = const Color(0xFF71BB7B);
        // For completion requests, always show interactive UI
        return _buildInteractiveCompletionRequest(message);
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCompletionRequest(HelpChatMessage message) {
    // Parse the message to extract the completion text
    final completionMessage = message.message.replaceFirst('✅ Requested help completion: ', '');
    
    // Create unique key for this completion request
    final requestKey = '${message.senderId}_${message.timestamp.millisecondsSinceEpoch}';
    final hasBeenResponded = _respondedCompletionRequests.contains(requestKey);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.amber[50]!, Colors.amber[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber[800],
                          ),
                        ),
                        Text(
                          'From ${message.senderName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeago.format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Completion message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Text(
                  completionMessage.isEmpty ? 'Help completed!' : completionMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Action buttons - show different content based on response status
              hasBeenResponded 
                  ? _buildCompletionResponseStatus() 
                  : (message.senderId == _currentUserId 
                      ? _buildOwnCompletionRequestStatus()
                      : _buildCompletionResponseButtons(message, requestKey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionResponseStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have already responded to this request.',
              style: TextStyle(
                color: Colors.green[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnCompletionRequestStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.amber[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Completion request sent. Waiting for response...',
              style: TextStyle(
                color: Colors.amber[800],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionResponseButtons(HelpChatMessage message, String requestKey) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleCompletionResponse(message, true, requestKey),
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text(
              'Accept',
              style: TextStyle(fontWeight: FontWeight.bold),
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
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleCompletionResponse(message, false, requestKey),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text(
              'Decline',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startDeletionCountdown() {
    if (_deletionTimer?.isActive == true) return; // Prevent multiple timers
    
    setState(() {
      _isCompleted = true;
      _remainingSeconds = 60;
    });

    _deletionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--; // Don't call setState to avoid rebuilding main widget

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _handleChatDeletion();
      }
    });
  }

  Future<void> _handleChatDeletion() async {
    try {
      // Delete the chat from backend
      await _chatService.deleteChat(widget.helpRequestId);
      
      // Navigate back to chat list
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat has been permanently deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error deleting chat: $e');
      }
    }
  }

  Widget _buildProgressButtons() {
    if (!widget.isRequester) {
      // Only responder can send progress updates
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          children: [
            Text(
              'Quick Progress Updates',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildProgressChip('On my way', HelpProgressStatus.onTheWay, Icons.directions_walk),
                _buildProgressChip('Arrived', HelpProgressStatus.arrived, Icons.location_on),
                _buildProgressChip('Started helping', HelpProgressStatus.helping, Icons.build),
                _buildProgressChip('Almost done', HelpProgressStatus.nearCompletion, Icons.schedule),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildProgressChip(String label, HelpProgressStatus status, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _sendProgressUpdate(status, label),
      backgroundColor: const Color(0xFF71BB7B).withOpacity(0.1),
      side: BorderSide(color: const Color(0xFF71BB7B).withOpacity(0.3)),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Completion request button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: (_isLoading || _hasPendingCompletionRequest || _isCompleted) 
                  ? null 
                  : _requestCompletion,
              icon: Icon(
                Icons.check_circle, 
                size: 18,
                color: (_hasPendingCompletionRequest || _isCompleted) 
                    ? Colors.grey 
                    : const Color(0xFF71BB7B),
              ),
              label: Text(
                _hasPendingCompletionRequest 
                    ? 'Completion Pending...' 
                    : _isCompleted 
                        ? 'Completed' 
                        : 'Mark as Complete'
              ),
              style: TextButton.styleFrom(
                foregroundColor: (_hasPendingCompletionRequest || _isCompleted) 
                    ? Colors.grey 
                    : const Color(0xFF71BB7B),
                backgroundColor: (_hasPendingCompletionRequest || _isCompleted) 
                    ? Colors.grey.withOpacity(0.1) 
                    : const Color(0xFF71BB7B).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: (_hasPendingCompletionRequest || _isCompleted) 
                        ? Colors.grey.withOpacity(0.3) 
                        : const Color(0xFF71BB7B).withOpacity(0.3)
                  ),
                ),
              ),
            ),
          ),
          
          // Message input
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF71BB7B),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending 
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 16,
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  iconSize: 20,
                ),
              ),
            ],
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPartyName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.helpRequestTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show help request details
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress update buttons for responder
          _buildProgressButtons(),
          
          // Countdown timer banner (shown when completed)
          if (_isCompleted) _CountdownBanner(remainingSeconds: _remainingSeconds),
          
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getChatMessages(widget.helpRequestId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: const Color(0xFF71BB7B),
                      size: 32,
                    ),
                  );
                }

                final messages = snapshot.data?.docs
                    .map((doc) => HelpChatMessage.fromJson({
                          'id': doc.id,
                          ...doc.data() as Map<String, dynamic>,
                        }))
                    .toList() ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isRequester
                              ? 'Communicate with your helper'
                              : 'Let them know your progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as read when they come in
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }
}

class _CompletionRequestDialog extends StatefulWidget {
  @override
  _CompletionRequestDialogState createState() => _CompletionRequestDialogState();
}

class _CompletionRequestDialogState extends State<_CompletionRequestDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark as Complete'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Let the other person know that the help is complete. They\'ll need to confirm before it\'s officially marked as done.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Optional: Add a completion message...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _controller.text.trim().isEmpty 
                ? 'Help has been completed!' 
                : _controller.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF71BB7B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Send Request'),
        ),
      ],
    );
  }
}

// Separate stateful widget for countdown to prevent main widget rebuilds
class _CountdownBanner extends StatefulWidget {
  final int initialSeconds;
  
  const _CountdownBanner({required int remainingSeconds}) : initialSeconds = remainingSeconds;

  @override
  State<_CountdownBanner> createState() => _CountdownBannerState();
}

class _CountdownBannerState extends State<_CountdownBanner> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[600]!, Colors.red[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Chat Auto-Delete: ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeString,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chat will be permanently deleted! Take screenshots now if needed.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
