import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neighborly/functions/init_pageval.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/app_routes.dart';
import 'community_list.dart';
import 'profile.dart';
import 'chat_screen.dart';
import 'help_history.dart';
import 'report_feedback.dart';
import 'blood_donation.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    required this.title,
    this.onNavigate,
    this.onNavigateToMapWithHelp,
  });
  final String title;
  final Function(int)? onNavigate;
  final VoidCallback? onNavigateToMapWithHelp;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerSlideAnimation;
  late PageController _carouselController;
  int _currentCarouselIndex = 0;

  static bool _hasAnimated = false;

  final List<Map<String, dynamic>> communityUpdates = [
    {
      'title': 'Community Garden Project',
      'description': 'Join us this weekend for planting!',
      'image': 'assets/images/Image1.jpg',
      'time': '2 hours ago',
    },
    {
      'title': 'Neighborhood Watch Meeting',
      'description': 'Safety discussion this Thursday 7PM',
      'image': 'assets/images/Image2.jpg',
      'time': '5 hours ago',
    },
    {
      'title': 'Local Food Drive',
      'description': 'Help families in need - donations welcome',
      'image': 'assets/images/Image3.jpg',
      'time': '1 day ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

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

    _carouselController = PageController();

    if (!_hasAnimated) {
      _animationController.forward();
      _headerAnimationController.forward();
      _hasAnimated = true;
    } else {
      _animationController.value = 1.0;
      _headerAnimationController.forward();
    }

    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _carouselController.hasClients) {
        int nextPage = (_currentCarouselIndex + 1) % communityUpdates.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentCarouselIndex = nextPage;
        });
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _makeEmergencyCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '999');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make emergency call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePage(title: 'Profile'),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF71BB7B), Color(0xFF5EA968), Color(0xFF4A9B5A)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF71BB7B).withOpacity(0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/images/dummy.png'),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${FirebaseAuth.instance.currentUser?.displayName}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What\'s happening in your neighborhood today?',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85), color.withOpacity(0.7)],
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
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
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
            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: Color(0xFF71BB7B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Forum',
                  Icons.forum_rounded,
                  const Color(0xFF6366F1),
                  () => widget.onNavigate?.call(3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Help List',
                  Icons.volunteer_activism,
                  const Color(0xFFEC4899),
                  () => widget.onNavigate?.call(0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Community',
                  Icons.groups_rounded,
                  const Color(0xFF10B981),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunityListPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  'Notifications',
                  Icons.notifications_active_rounded,
                  const Color(0xFFF59E0B),
                  () => widget.onNavigate?.call(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapHighlight() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => widget.onNavigate?.call(1),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF71BB7B),
                Color(0xFF5EA968),
                Color(0xFF4A9B5A),
                Color(0xFF3D8A4B),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF71BB7B).withOpacity(0.4),
                offset: const Offset(0, 12),
                blurRadius: 28,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -60,
                top: -20,
                child: Icon(
                  Icons.public,
                  size: 140,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                          Icons.explore,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Explore Your Area',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover help requests, community events, and connect with neighbors around you.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Map',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBloodDonationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bloodtype, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Blood Donation',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Blood Donation Card
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE53E3E),
                  Color(0xFFDC2626),
                  Color(0xFFB91C1C),
                  Color(0xFF991B1B),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  offset: const Offset(0, 12),
                  blurRadius: 28,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -60,
                  top: -20,
                  child: Icon(
                    Icons.favorite,
                    size: 140,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                // Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                            Icons.bloodtype,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Save Lives Today',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Find blood donors in your area or register yourself as a donor to help your community in emergency situations.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const BloodDonationPage(
                                        initialTabIndex: 0, // Find Donors tab
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Find Donors',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const BloodDonationPage(
                                        initialTabIndex: 1, // Become Donor tab
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Join Donors',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Color(0xFF71BB7B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Community Updates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CommunityListPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF71BB7B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            itemCount: communityUpdates.length,
            itemBuilder: (context, index) {
              final update = communityUpdates[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.asset(
                        update['image'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 24,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF71BB7B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                update['time'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              update['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              update['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.95),
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            communityUpdates.length,
            (index) => Container(
              width: _currentCarouselIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color:
                    _currentCarouselIndex == index
                        ? const Color(0xFF71BB7B)
                        : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserSidebar() {
    String username = "Ali";

    void signOut() async {
      ref.read(hasSeenSplashProvider.notifier).state =
          true; // Ensure direct auth access
      initPageVal(ref);
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('rememberMe', false);
      ref.read(authUserProvider.notifier).initState();
      await FirebaseAuth.instance.signOut();
    }

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF71BB7B), Color(0xFF5EA968), Color(0xFF4A9B5A)],
        ),
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.only(
                top: 15,
                left: 24,
                right: 24,
                bottom: 16,
              ),
              child: Column(
                children: [
                  // Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User Profile Section
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => const ProfilePage(title: 'Profile'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const CircleAvatar(
                              radius: 26,
                              backgroundImage: AssetImage(
                                'assets/images/dummy.png',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $username! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tap to view profile',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildMenuCategory('Quick Actions', Icons.flash_on, [
                            _buildMenuItem(
                              'Notifications',
                              Icons.notifications_rounded,
                              Colors.orange,
                              () {
                                Navigator.pop(context);
                                widget.onNavigate?.call(4);
                              },
                            ),
                            _buildMenuItem(
                              'Community List',
                              Icons.people_rounded,
                              Colors.blue,
                              () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const CommunityListPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'Help Requests',
                              Icons.volunteer_activism,
                              Colors.pink,
                              () {
                                Navigator.pop(context);
                                widget.onNavigate?.call(0);
                              },
                            ),
                          ]),
                          const SizedBox(height: 20),
                          _buildMenuCategory('More Options', Icons.apps, [
                            _buildMenuItem(
                              'Help History',
                              Icons.history,
                              Colors.purple,
                              () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const HelpHistoryPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'Report & Feedback',
                              Icons.feedback_rounded,
                              Colors.teal,
                              () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const ReportFeedbackPage(),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              'Forum',
                              Icons.forum_rounded,
                              Colors.indigo,
                              () {
                                Navigator.pop(context);
                                widget.onNavigate?.call(3);
                              },
                            ),
                            _buildMenuItem(
                              'Blood Donation',
                              Icons.bloodtype,
                              Colors.red,
                              () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const BloodDonationPage(
                                          initialTabIndex:
                                              0, // Default to Find Donors
                                        ),
                                  ),
                                );
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),

                    // Logout Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showLogoutDialog(signOut);
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Log Out'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCategory(String title, IconData icon, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF71BB7B), size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(VoidCallback signOut) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text("Confirm Logout"),
              ],
            ),
            content: const Text(
              "Are you sure you want to log out of your account?",
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  signOut();
                },
                child: const Text("Log Out"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      endDrawer: _buildUserSidebar(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        automaticallyImplyLeading: false,
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
                      Icons.home,
                      color: Color(0xFFFAF4E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Neighborly',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                _makeEmergencyCall();
              },
              icon: const Icon(Icons.emergency, color: Colors.white, size: 18),
              label: const Text(
                'Call 999',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              icon: const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/dummy.png'),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Use the specialized callback to navigate to map and auto-open help drawer
          if (widget.onNavigateToMapWithHelp != null) {
            widget.onNavigateToMapWithHelp!();
          } else {
            // Fallback to regular navigation if callback not available
            widget.onNavigate?.call(1);
          }
        },
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        tooltip: "Add Help Request",
        child: const Icon(Icons.add, size: 28),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 28),
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildMapHighlight(),
              const SizedBox(height: 40),
              _buildQuickActions(),
              const SizedBox(height: 40),
              _buildBloodDonationSection(),
              const SizedBox(height: 40),
              _buildCommunityCarousel(),
              const SizedBox(height: 32),
              _buildNotificationPreview(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationPreview() {
    final List<String> names = [
      "Jack Conniler",
      "Sual Canal",
      "Samuel Badre",
      "Alice Johnson",
      "Bob Smith",
    ];

    final List<String> messages = [
      "Wants Grocery",
      "Wants Emergency Ambulance Service",
      "Gave a traffic update",
      "Has lost her pet cat named Sania",
      "Needs help with trash pickup",
    ];

    final List<String> images = [
      'assets/images/Image1.jpg',
      'assets/images/Image2.jpg',
      'assets/images/Image3.jpg',
      'assets/images/Image1.jpg',
      'assets/images/Image2.jpg',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'NeighborBot',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text(
                    "Ask AI",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF71BB7B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Latest Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: names.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            images[index],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              names[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              messages[index],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF71BB7B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: GestureDetector(
                          onTap: () => widget.onNavigate?.call(4),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFF71BB7B),
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
      ),
    );
  }
}
