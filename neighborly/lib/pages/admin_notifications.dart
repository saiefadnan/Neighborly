import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neighborly/models/event.dart';
import 'package:neighborly/pages/event_details.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _fadeController.dispose();
    super.dispose();
  }

  AdminNotification _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Map Firestore fields to your model
    return AdminNotification(
      id: doc.id,
      type: _mapType(data['type']),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['createdAt'] is Timestamp)
          ? data['createdAt'].toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isRead: data['read'] ?? false,
      communityName: data['communityId'],
      actorName: data['actorName'],
      targetName: data['recipientEmail'],
      icon: _mapIcon(data['type']),
      color: _mapColor(data['type']),
      eventData: (data['eventData'] != null)
          ? EventModel(
              id: data['eventData']['id'] ?? '',
              title: data['eventData']['title'] ?? '',
              description: data['eventData']['description'] ?? '',
              imageUrl: data['eventData']['imageUrl'] ?? '',
              approved: data['eventData']['approved'] ?? false,
              createdAt: data['eventData']['createdAt'] ?? Timestamp.now(),
              location: data['eventData']['location'] ?? '',
              lng: data['eventData']['lng'] ?? 0.0,
              lat: data['eventData']['lat'] ?? 0.0,
              raduis: data['eventData']['raduis'] ?? 0,
              tags: List<String>.from(data['eventData']['tags'] ?? []),
            )
          : null,
    );
  }

  NotificationType _mapType(String? type) {
    switch (type) {
      case 'member_approval':
        return NotificationType.memberApproval;
      case 'event_approval':
        return NotificationType.eventApproval;
      case 'admin_added':
        return NotificationType.adminAdded;
      case 'milestone':
        return NotificationType.milestone;
      case 'admin_action':
      case 'user_action':
        return NotificationType.userAction;
      case 'security':
        return NotificationType.security;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  IconData _mapIcon(String? type) {
    switch (type) {
      case 'member_approval':
        return Icons.person_add;
      case 'event_approval':
        return Icons.event;
      case 'admin_added':
        return Icons.admin_panel_settings;
      case 'milestone':
        return Icons.celebration;
      case 'admin_action':
      case 'user_action':
        return Icons.block;
      case 'security':
        return Icons.security;
      case 'system':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  Color _mapColor(String? type) {
    switch (type) {
      case 'member_approval':
        return const Color(0xFF10B981);
      case 'event_approval':
        return const Color(0xFF8B5CF6);
      case 'admin_added':
        return const Color(0xFFF59E0B);
      case 'milestone':
        return const Color(0xFFFFD700);
      case 'admin_action':
      case 'user_action':
        return const Color(0xFFEF4444);
      case 'security':
        return const Color(0xFFFF6B6B);
      case 'system':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6366F1);
    }
  }

  int _unreadCount(List<AdminNotification> notifications) =>
      notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data?.docs
                    .map(_fromFirestore)
                    .toList() ??
                [];

            return Column(
              children: [
                _buildStatsHeader(notifications),
                Expanded(
                  child: notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'re all caught up!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(notifications[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsHeader(List<AdminNotification> notifications) {
    final unreadCount = _unreadCount(notifications);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 24,
                ),//Notifications updated and connected to database
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Admin Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBadge(
                'Total',
                notifications.length.toString(),
                Icons.inbox,
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                'Unread',
                unreadCount.toString(),
                Icons.mark_email_unread,
              ),
              const SizedBox(width: 12),
              _buildStatBadge(
                'Action Needed',
                notifications
                    .where(
                      (n) =>
                          n.type == NotificationType.eventApproval && !n.isRead,
                    )
                    .length
                    .toString(),
                Icons.pending_actions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotification notification) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: notification.isRead
            ? null
            : Border.all(
                color: notification.color.withOpacity(0.3),
                width: 1,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(notification.isRead ? 0.05 : 0.08),
            blurRadius: notification.isRead ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: notification.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: notification.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (notification.communityName != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: notification.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                notification.communityName!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: notification.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _formatTimeAgo(notification.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (notification.type ==
                                  NotificationType.eventApproval &&
                              !notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Action Required',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!notification.isRead)
                            TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .doc(notification.id)
                                    .update({'read': true});
                              },
                              child: const Text(
                                'Mark as Read',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}

// Data Models
class AdminNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  final String? communityName;
  final String? actorName;
  final String? targetName;
  final IconData icon;
  final Color color;
  final EventModel? eventData;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.communityName,
    this.actorName,
    this.targetName,
    required this.icon,
    required this.color,
    this.eventData,
  });
}

enum NotificationType {
  memberApproval,
  eventApproval,
  adminAdded,
  milestone,
  userAction,
  security,
  system,
}
