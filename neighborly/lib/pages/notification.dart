import 'package:flutter/material.dart';

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

// Beautiful Enhanced NotificationCard Widget
class NotificationCard extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onAction,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getUrgencyColor() {
    switch (widget.notification.urgency) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      default:
        return const Color(0xFF71BB7B);
    }
  }

  IconData _getTypeIcon() {
    switch (widget.notification.type) {
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
    final difference = now.difference(widget.notification.timestamp);

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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
              widget.onTap?.call();
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getUrgencyColor().withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: _getUrgencyColor().withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  // Urgency indicator bar
                  Positioned(
                    left: 0,
                    top: 16,
                    bottom: 16,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: _getUrgencyColor(),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Profile image with online indicator
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    widget.notification.image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                if (widget.notification.urgency == 'emergency')
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.priority_high,
                                        size: 8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Name and type
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.notification.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getUrgencyColor().withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          widget.notification.urgency
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getUrgencyColor(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        _getTypeIcon(),
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.notification.type
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Time and read indicator
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _getTimeAgo(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (!widget.notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _getUrgencyColor(),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Message
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Location (if available)
                        if (widget.notification.location != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.notification.location!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onAction,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getUrgencyColor(),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text(
                                  'View Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                // Handle message action - dismiss previous and show new
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.message,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Starting conversation with ${widget.notification.name}...',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: _getUrgencyColor(),
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    action: SnackBarAction(
                                      label: 'Open Chat',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        // Handle open chat action
                                      },
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _getUrgencyColor(),
                                side: BorderSide(color: _getUrgencyColor()),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.message, size: 16),
                              label: const Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.title, this.onNavigate});
  final String title;
  final Function(int)? onNavigate;

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

  List<NotificationData> _notifications = [
    NotificationData(
      id: '1',
      name: 'Jack Conniler',
      message:
          'Needs immediate medical assistance. Please help if you\'re nearby with medical training.',
      image: 'assets/images/Image1.jpg',
      urgency: 'emergency',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      location: 'Dhanmondi 15, Dhaka',
    ),
    NotificationData(
      id: '2',
      name: 'Sual Canal',
      message:
          'Emergency ambulance service required immediately. Patient is unconscious.',
      image: 'assets/images/Image2.jpg',
      urgency: 'emergency',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      location: 'Gulshan 2, Dhaka',
    ),
    NotificationData(
      id: '3',
      name: 'Samuel Badre',
      message: 'Looking for help with grocery shopping for elderly neighbor.',
      image: 'assets/images/Image3.jpg',
      urgency: 'urgent',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      location: 'Bashundhara R/A, Dhaka',
    ),
    NotificationData(
      id: '4',
      name: 'Alice Johnson',
      message:
          'Traffic jam reported on main road. Alternative routes suggested.',
      image: 'assets/images/Image1.jpg',
      urgency: 'normal',
      type: 'traffic_update',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      location: 'Dhanmondi 27, Dhaka',
    ),
    NotificationData(
      id: '5',
      name: 'Bob Smith',
      message:
          'Lost pet cat named Sania. Last seen near the park. Please help find her.',
      image: 'assets/images/Image2.jpg',
      urgency: 'urgent',
      type: 'lost_pet',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      location: 'Wari, Dhaka',
    ),
    NotificationData(
      id: '6',
      name: 'Charlie Davis',
      message:
          'Community meeting scheduled for tomorrow evening. All neighbors welcome.',
      image: 'assets/images/Image3.jpg',
      urgency: 'normal',
      type: 'community',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      location: 'Community Center, Dhanmondi',
    ),
    NotificationData(
      id: '7',
      name: 'Dana White',
      message:
          'Need help moving furniture to 4th floor. Willing to provide refreshments.',
      image: 'assets/images/Image1.jpg',
      urgency: 'normal',
      type: 'help_request',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      location: 'Mirpur 10, Dhaka',
    ),
  ];

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
    setState(() {
      _notifications =
          _notifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();
    });
  }

  // Method to mark a single notification as read
  void _markAsRead(String notificationId) {
    setState(() {
      _notifications =
          _notifications
              .map(
                (notification) =>
                    notification.id == notificationId
                        ? notification.copyWith(isRead: true)
                        : notification,
              )
              .toList();
    });
  }

  // Method to undo mark all as read
  void _undoMarkAllAsRead() {
    setState(() {
      _notifications =
          _notifications
              .map((notification) => notification.copyWith(isRead: false))
              .toList();
    });
  }

  List<NotificationData> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((notification) {
      return notification.urgency.toLowerCase() ==
          _selectedFilter.toLowerCase();
    }).toList();
  }

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
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

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final count =
        filter == 'All'
            ? _notifications.length
            : _notifications
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
    final filteredNotifications = _filteredNotifications;

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
                          '$_unreadCount unread messages',
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
              children: _filters.map(_buildFilterChip).toList(),
            ),
          ),

          // Notifications List
          Expanded(
            child:
                filteredNotifications.isEmpty
                    ? _buildEmptyState()
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

                            // Handle notification tap - dismiss previous and show new
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        notification.image,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Viewing ${notification.name}\'s request',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            notification.type
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      notification.urgency == 'emergency'
                                          ? Icons.priority_high
                                          : Icons.info_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                backgroundColor: _getNotificationColor(
                                  notification.urgency,
                                ),
                                duration: const Duration(seconds: 4),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: SnackBarAction(
                                  label: 'Details',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Handle view details action
                                  },
                                ),
                              ),
                            );
                          },
                          onAction: () {
                            // Navigate directly to map tab (index 1)
                            widget.onNavigate?.call(1);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No ${_selectedFilter.toLowerCase()} notifications',
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
