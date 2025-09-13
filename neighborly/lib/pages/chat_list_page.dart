import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neighborly/pages/help_chat_page.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLastMessage(String helpRequestId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('helpChats')
          .doc(helpRequestId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final messageData = snapshot.docs.first.data();
        return {
          'message': messageData['message'] ?? '',
          'timestamp': messageData['timestamp'],
          'senderId': messageData['senderId'] ?? '',
          'type': messageData['type'] ?? 'text',
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int> _getUnreadCount(String helpRequestId) async {
    if (_currentUserId == null) return 0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('helpChats')
          .doc(helpRequestId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildChatTile(Map<String, dynamic> helpRequest) {
    final helpRequestId = helpRequest['id'] ?? '';
    final isRequester = helpRequest['requesterId'] == _currentUserId;
    final otherPartyName = isRequester 
        ? (helpRequest['responderName'] ?? 'Helper')
        : (helpRequest['requesterName'] ?? 'Requester');
    final otherPartyId = isRequester 
        ? helpRequest['responderId'] 
        : helpRequest['requesterId'];
    final helpTitle = helpRequest['originalRequestData']?['title'] ?? 'Help Request';
    final status = helpRequest['status'] ?? 'in_progress';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getLastMessage(helpRequestId),
      builder: (context, messageSnapshot) {
        return FutureBuilder<int>(
          future: _getUnreadCount(helpRequestId),
          builder: (context, unreadSnapshot) {
            final lastMessage = messageSnapshot.data;
            final unreadCount = unreadSnapshot.data ?? 0;
            final hasLastMessage = lastMessage != null;
            
            String lastMessageText = 'Start conversation';
            String timeText = '';
            
            if (hasLastMessage) {
              final messageText = lastMessage['message'] ?? '';
              final messageType = lastMessage['type'] ?? 'text';
              
              if (messageType == 'progressUpdate') {
                lastMessageText = '📍 ${messageText.replaceAll('📍 ', '')}';
              } else if (messageType == 'completionRequest') {
                lastMessageText = '✅ ${messageText.replaceAll('✅ ', '')}';
              } else {
                lastMessageText = messageText.length > 50 
                    ? '${messageText.substring(0, 50)}...' 
                    : messageText;
              }
              
              if (lastMessage['timestamp'] != null) {
                final timestamp = lastMessage['timestamp'] is Timestamp
                    ? (lastMessage['timestamp'] as Timestamp).toDate()
                    : DateTime.parse(lastMessage['timestamp']);
                timeText = timeago.format(timestamp);
              }
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: unreadCount > 0 ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF71BB7B).withOpacity(0.1),
                      child: Text(
                        otherPartyName.isNotEmpty ? otherPartyName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF71BB7B),
                        ),
                      ),
                    ),
                    if (status == 'pending_completion')
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.schedule,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherPartyName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? const Color(0xFF71BB7B) : Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      helpTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71BB7B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessageText,
                            style: TextStyle(
                              fontSize: 14,
                              color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF71BB7B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (status == 'pending_completion')
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Completion pending',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HelpChatPage(
                        helpRequestId: helpRequestId,
                        helpRequestTitle: helpTitle,
                        otherPartyName: otherPartyName,
                        otherPartyId: otherPartyId,
                        isRequester: isRequester,
                      ),
                    ),
                  );
                },
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF71BB7B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Color(0xFF71BB7B),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Active Chats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When you have active help requests,\nyour conversations will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Go back to map to create help requests
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Help Request'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF71BB7B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Chats'),
          backgroundColor: const Color(0xFF71BB7B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Please sign in to view your chats',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _currentUserId != null 
            ? FirebaseFirestore.instance
                .collection('helpedRequests')
                .where('status', whereIn: ['in_progress', 'pending_completion'])
                .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading chats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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

          final docs = snapshot.data?.docs ?? [];
          
          // Filter to only show chats where current user is involved
          final myChats = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['requesterId'] == _currentUserId || 
                   data['responderId'] == _currentUserId;
          }).map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }).toList();

          if (myChats.isEmpty) {
            return _buildEmptyState();
          }

          // Sort by last activity (most recent first)
          myChats.sort((a, b) {
            final aUpdated = a['updatedAt'];
            final bUpdated = b['updatedAt'];
            
            if (aUpdated == null && bUpdated == null) return 0;
            if (aUpdated == null) return 1;
            if (bUpdated == null) return -1;
            
            final aTime = aUpdated is Timestamp ? aUpdated.toDate() : DateTime.parse(aUpdated.toString());
            final bTime = bUpdated is Timestamp ? bUpdated.toDate() : DateTime.parse(bUpdated.toString());
            
            return bTime.compareTo(aTime);
          });

          return Column(
            children: [
              // Status info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF71BB7B).withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF71BB7B),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Active conversations from your help requests',
                        style: TextStyle(
                          color: const Color(0xFF71BB7B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat list
              Expanded(
                child: ListView.builder(
                  itemCount: myChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatTile(myChats[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
