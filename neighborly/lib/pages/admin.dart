import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neighborly/pages/admin_community_management.dart';
import 'users.dart';
import 'announcements.dart';
import 'team.dart';
import 'Schedule.dart';
import 'admin_notifications.dart';

//included backend connection
class AdminHomePage extends StatefulWidget {
  final void Function(int)? onNavigate;
  const AdminHomePage({super.key, this.onNavigate});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerSlideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  // Mock notification count - in real app this would come from Firebase
  final int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerSlideController,
        curve: Curves.easeOutBack,
      ),
    );
    _fadeController.forward();
    _headerSlideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerSlideController.dispose();
    super.dispose();
  }

  Widget _buildGreetingSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF71BB7B), Color(0xFF5EA968), Color(0xFF4A9B5A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF71BB7B).withOpacity(0.3),
              offset: const Offset(0, 8),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Welcome back, Admin!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Manage your community with ease',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badgeCount,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withOpacity(0.85),
                  color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background pattern - darkened slightly in dark mode
                  Positioned(
                    right: -15,
                    top: -15,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isDark
                                ? Colors.black.withOpacity(0.15)
                                : Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -30,
                    top: 0,
                    bottom: 0,
                    child: Icon(
                      icon,
                      size: 70,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  // Content with better constraints
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.bottomLeft,
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: 0.3,
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Notification badge
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFF71BB7B),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (context) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  return Text(
                    'Admin Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.grey[800],
                      letterSpacing: -0.3,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Adjust grid for different screen sizes
              final screenWidth = constraints.maxWidth;
              final crossAxisCount = screenWidth > 600 ? 3 : 2;
              final aspectRatio = screenWidth > 600 ? 1.4 : 1.5;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: aspectRatio,
                children: [
                  _buildActionCard(
                    'Community Management',
                    Icons.group_work_rounded,
                    const Color(0xFF10B981),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCommunityManagementPage(),
                      ),
                    ),
                  ),
                  _buildActionCard(
                    'Community Admins',
                    Icons.supervised_user_circle_rounded,
                    const Color(0xFFF59E0B),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeamPage()),
                    ),
                  ),
                  _buildActionCard(
                    'Community Users',
                    Icons.people_rounded,
                    const Color(0xFF06B6D4),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UsersPage()),
                    ),
                  ),
                  _buildActionCard(
                    'Announcements',
                    Icons.campaign_rounded,
                    const Color(0xFF8B5CF6),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnnouncementsPage(),
                      ),
                    ),
                  ),
                  _buildActionCard(
                    'Schedules',
                    Icons.schedule_rounded,
                    const Color(0xFF3B82F6),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchedulePage()),
                    ),
                  ),
                  _buildActionCard(
                    'Admin Notifications',
                    Icons.notifications_rounded,
                    const Color(0xFF6366F1),
                    () {
                      // Add admin notifications navigation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => Scaffold(body: AdminNotificationsPage()),
                        ),
                      );
                    },
                    badgeCount: _notificationCount,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return SlideTransition(
              position: _headerSlideAnimation,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFFFAF4E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Color(0xFFFAF4E8),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(),
            const SizedBox(height: 10),
            _buildQuickActions(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
