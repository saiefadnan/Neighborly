import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/notification_provider.dart';

// Enhanced Notification Model
class NotificationData {
  final String id;
  final String name;
  final String message;
  final String image;
  final String urgency; // 'emergency', 'urgent', 'normal'
  final String
  type; // 'help_request', 'traffic_update', 'lost_pet', 'community'
  final DateTime timestamp;
  final bool isRead;
  final String? location;
  final Map<String, dynamic>? extraData;

  NotificationData({
    required this.id,
    required this.name,
    required this.message,
    required this.image,
    required this.urgency,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.location,
    this.extraData,
  });

  // Method to create a copy with updated read status
  NotificationData copyWith({
    String? id,
    String? name,
    String? message,
    String? image,
    String? urgency,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? location,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationData(
      id: id ?? this.id,
      name: name ?? this.name,
      message: message ?? this.message,
      image: image ?? this.image,
      urgency: urgency ?? this.urgency,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      location: location ?? this.location,
      extraData: extraData ?? this.extraData,
    );
  }
}

// Lightweight NotificationCard Widget (Facebook-style)
class NotificationCard extends StatelessWidget {
  final NotificationData notification;
  final VoidCallback? onTap;

  const NotificationCard({super.key, required this.notification, this.onTap});

  Color _getUrgencyColor() {
    switch (notification.urgency) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return const Color(0xFF71BB7B);
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case 'help_request':
        return Icons.volunteer_activism;
      case 'traffic_update':
        return Icons.traffic;
      case 'lost_pet':
        return Icons.pets;
      case 'community':
        return Icons.people;
      default:
        return Icons.notifications;
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: _getUrgencyColor().withOpacity(0.1),
        highlightColor: _getUrgencyColor().withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image with urgency indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(notification.image),
                  ),
                  if (notification.urgency == 'emergency')
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message with name
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1C1E21),
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: notification.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' ${notification.message}'),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Time and type info
                    Row(
                      children: [
                        Text(
                          _getTimeAgo(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getTypeIcon(),
                          size: 12,
                          color: _getUrgencyColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification.type.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getUrgencyColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Location (if available)
                    if (notification.location != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              notification.location!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Read indicator and urgency badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (notification.urgency != 'normal') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getUrgencyColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        notification.urgency.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: _getUrgencyColor(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({
    super.key,
    required this.title,
    this.onNavigate,
    this.onLocationNavigate,
  });
  final String title;
  final Function(int)? onNavigate;
  final Function(LatLng, String)?
  onLocationNavigate; // Callback for location navigation

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Emergency', 'Urgent', 'Normal'];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  // Method to mark all notifications as read
  void _markAllAsRead() {
    Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
  }

  // Method to mark a single notification as read
  void _markAsRead(String notificationId) {
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).markAsRead(notificationId);
  }

  // Method to undo mark all as read
  void _undoMarkAllAsRead() {
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).undoMarkAllAsRead();
  }

  Color _getNotificationColor(String urgency) {
    switch (urgency) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return const Color(0xFF71BB7B);
    }
  }

  Widget _buildFilterChip(String filter, NotificationProvider provider) {
    final isSelected = _selectedFilter == filter;
    final count =
        filter == 'All'
            ? provider.notifications.length
            : provider.notifications
                .where((n) => n.urgency.toLowerCase() == filter.toLowerCase())
                .length;

    Color filterColor;
    switch (filter.toLowerCase()) {
      case 'emergency':
        filterColor = Colors.red;
        break;
      case 'urgent':
        filterColor = Colors.orange;
        break;
      case 'normal':
        filterColor = const Color(0xFF71BB7B);
        break;
      default:
        filterColor = const Color(0xFF71BB7B);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? filterColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: filterColor, width: 1.5),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: filterColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: TextStyle(
                color: isSelected ? Colors.white : filterColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withOpacity(0.2)
                        : filterColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : filterColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the provider directly without Consumer for now
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final filteredNotifications = notificationProvider.getFilteredNotifications(
      _selectedFilter,
    );
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF71BB7B),
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$unreadCount unread messages',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: AnimatedBuilder(
              animation: _buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: GestureDetector(
                    onTapDown: (_) {
                      _buttonAnimationController.forward();
                    },
                    onTapUp: (_) {
                      _buttonAnimationController.reverse();
                    },
                    onTapCancel: () {
                      _buttonAnimationController.reverse();
                    },
                    child: TextButton.icon(
                      onPressed: () {
                        // Mark all as read functionality - actually update the state
                        _markAllAsRead();

                        // Clear previous and show new snackbar
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.done_all,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'All notifications marked as read',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: const Color(0xFF71BB7B),
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              textColor: Colors.white,
                              onPressed: () {
                                // Handle undo action - restore all to unread
                                _undoMarkAllAsRead();
                              },
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        overlayColor:
                            Colors.transparent, // Removes default splash
                      ),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text(
                        'Mark as Read',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  _filters
                      .map(
                        (filter) =>
                            _buildFilterChip(filter, notificationProvider),
                      )
                      .toList(),
            ),
          ),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                print('🔄 Refreshing notifications...');
                await notificationProvider.initializeNotifications();
                print('✅ Notifications refresh completed');
              },
              color: const Color(0xFF71BB7B),
              child:
                  filteredNotifications.isEmpty
                      ? _buildEmptyState(_selectedFilter)
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = filteredNotifications[index];
                          return NotificationCard(
                            notification: notification,
                            onTap: () {
                              // Mark this notification as read
                              _markAsRead(notification.id);

                              // Navigate to map with location
                              if (notification.extraData != null &&
                                  notification.extraData!['coordinates'] !=
                                      null) {
                                final coords =
                                    notification.extraData!['coordinates']
                                        as Map<String, dynamic>;
                                final location = LatLng(
                                  coords['lat'].toDouble(),
                                  coords['lng'].toDouble(),
                                );

                                // Navigate to map with location
                                if (widget.onLocationNavigate != null) {
                                  widget.onLocationNavigate!(
                                    location,
                                    notification.name,
                                  );
                                } else {
                                  // Fallback to just navigate to map tab
                                  widget.onNavigate?.call(1);
                                }
                              } else {
                                // Fallback to just navigate to map tab
                                widget.onNavigate?.call(1);
                              }

                              // Show subtle feedback
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Opening ${notification.name}\'s location on map',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: _getNotificationColor(
                                    notification.urgency,
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String selectedFilter) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${selectedFilter.toLowerCase()} notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates from your community',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
