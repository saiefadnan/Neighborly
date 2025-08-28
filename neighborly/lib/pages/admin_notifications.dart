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

  final List<AdminNotification> _notifications = [
    // Community Join Approvals
    AdminNotification(
      id: '1',
      type: NotificationType.memberApproval,
      title: 'New Member Approved',
      message: 'John Doe was accepted into Dhanmondi by Admin Sarah',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      communityName: 'Dhanmondi',
      actorName: 'Sarah Ahmed',
      targetName: 'John Doe',
      icon: Icons.person_add,
      color: const Color(0xFF10B981),
    ),

    // Event Management
    AdminNotification(
      id: '2',
      type: NotificationType.eventApproval,
      title: 'Event Needs Approval',
      message: 'Community Cleanup Drive requires your approval',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      communityName: 'Gulshan',
      actorName: 'Fatima Khan',
      icon: Icons.event,
      color: const Color(0xFF8B5CF6),
      eventData: EventModel(
        title: 'Community Cleanup Drive',
        description:
            'Join us for a neighborhood cleanup to make our community beautiful!',
        imageUrl: 'assets/images/Image1.jpg',
        joined: 'false',
        date: DateTime.now().add(const Duration(days: 7)),
        location: 'Gulshan Park',
        lng: 90.4125,
        lat: 23.7808,
        tags: ['community', 'environment', 'cleanup'],
      ),
    ),

    // Admin Addition
    AdminNotification(
      id: '3',
      type: NotificationType.adminAdded,
      title: 'New Admin Added',
      message: 'Maria Khan was added as admin to Bashundhara',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
      communityName: 'Bashundhara',
      actorName: 'System Admin',
      targetName: 'Maria Khan',
      icon: Icons.admin_panel_settings,
      color: const Color(0xFFF59E0B),
    ),

    // Community Milestone
    AdminNotification(
      id: '4',
      type: NotificationType.milestone,
      title: 'Community Milestone! 🎉',
      message: 'Dhanmondi community reached 1000 members!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      communityName: 'Dhanmondi',
      icon: Icons.celebration,
      color: const Color(0xFFFFD700),
    ),

    // User Block Alert
    AdminNotification(
      id: '5',
      type: NotificationType.userAction,
      title: 'User Blocked',
      message: 'Admin John blocked user "AbusiveUser123" from Gulshan',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      communityName: 'Gulshan',
      actorName: 'John Admin',
      targetName: 'AbusiveUser123',
      icon: Icons.block,
      color: const Color(0xFFEF4444),
    ),

    // Security Alert
    AdminNotification(
      id: '6',
      type: NotificationType.security,
      title: 'Security Alert',
      message: 'Multiple spam reports received for user "SpamBot456"',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      communityName: 'Bashundhara',
      targetName: 'SpamBot456',
      icon: Icons.security,
      color: const Color(0xFFFF6B6B),
    ),

    // System Update
    AdminNotification(
      id: '7',
      type: NotificationType.system,
      title: 'System Update',
      message: 'New community guidelines have been published',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
      icon: Icons.update,
      color: const Color(0xFF06B6D4),
    ),

    // Anniversary Milestone
    AdminNotification(
      id: '8',
      type: NotificationType.milestone,
      title: 'Anniversary Milestone! 🎂',
      message: 'Gulshan community is celebrating its 2nd anniversary',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
      isRead: true,
      communityName: 'Gulshan',
      icon: Icons.cake,
      color: const Color(0xFFFF69B4),
    ),
  ];

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

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAsRead(String notificationId) {
    setState(() {
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
      );
      notification.isRead = true;
    });
    HapticFeedback.lightImpact();
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationTap(AdminNotification notification) {
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Handle different notification types
    switch (notification.type) {
      case NotificationType.eventApproval:
        if (notification.eventData != null) {
          _showEventApprovalDialog(notification);
        }
        break;
      case NotificationType.memberApproval:
      case NotificationType.adminAdded:
      case NotificationType.milestone:
      case NotificationType.userAction:
      case NotificationType.security:
      case NotificationType.system:
        // For other types, just mark as read (already handled above)
        break;
    }
  }

  void _showEventApprovalDialog(AdminNotification notification) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.event, color: notification.color, size: 24),
                const SizedBox(width: 8),
                const Expanded(child: Text('Event Approval Required')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.eventData!.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.eventData!.description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      notification.eventData!.location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${notification.eventData!.date.day}/${notification.eventData!.date.month}/${notification.eventData!.date.year}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _approveEvent(notification, false);
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              EventDetailsPage(event: notification.eventData!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Details'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _approveEvent(notification, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  void _approveEvent(AdminNotification notification, bool approved) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          approved
              ? 'Event "${notification.eventData!.title}" approved'
              : 'Event "${notification.eventData!.title}" rejected',
        ),
        backgroundColor: approved ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildStatsHeader() {
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
                ),
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
                _notifications.length.toString(),
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
                _notifications
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
        border:
            notification.isRead
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
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon with color indicator
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

                // Content
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
                                fontWeight:
                                    notification.isRead
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
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'read':
                        _markAsRead(notification.id);
                        break;
                      case 'delete':
                        _deleteNotification(notification.id);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        if (!notification.isRead)
                          const PopupMenuItem(
                            value: 'read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, size: 16),
                                SizedBox(width: 8),
                                Text('Mark as read'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ),
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
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildStatsHeader(),
            Expanded(
              child:
                  _notifications.isEmpty
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
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_notifications[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
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
