import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../services/community_service.dart'
    show CommunityService, CommunityUser;
import '../services/community_block_service.dart';
import '../services/join_request_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Community data from Firestore
  List<CommunityData> _communities = [];
  bool _isLoading = true;
  String? _error;

  // Services
  final CommunityBlockService _blockService = CommunityBlockService();
  final JoinRequestService _joinRequestService = JoinRequestService();

  // Mock users data - simulating Firebase users collection
  final List<CommunityUser> _allUsers = [
    // Dhanmondi Users
    CommunityUser(
      userId: '1',
      username: 'Sarah Ahmed',
      email: 'sarah.ahmed@example.com',
      profileImage: 'assets/images/Image1.jpg',
      preferredCommunity: 'dhanmondi',
      isAdmin: false,
      blocked: false,
      joinedDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CommunityUser(
      userId: '2',
      username: 'Karim Hassan',
      email: 'karim.hassan@example.com',
      profileImage: 'assets/images/Image2.jpg',
      preferredCommunity: 'dhanmondi',
      isAdmin: false,
      blocked: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 45)),
      blockedDate: DateTime.now().subtract(const Duration(days: 5)),
      blockedReason: 'Inappropriate behavior in community chat',
    ),
    CommunityUser(
      userId: '3',
      username: 'Rashida Begum',
      email: 'rashida.begum@example.com',
      profileImage: 'assets/images/Image3.jpg',
      preferredCommunity: 'dhanmondi',
      isAdmin: false,
      blocked: false,
      joinedDate: DateTime.now().subtract(const Duration(days: 15)),
    ),

    // Gulshan Users
    CommunityUser(
      userId: '4',
      username: 'Ali Rahman',
      email: 'ali.rahman@example.com',
      profileImage: 'assets/images/dummy.png',
      preferredCommunity: 'gulshan',
      isAdmin: false,
      blocked: false,
      joinedDate: DateTime.now().subtract(const Duration(days: 20)),
    ),
    CommunityUser(
      userId: '5',
      username: 'Fatima Khan',
      email: 'fatima.khan@example.com',
      profileImage: 'assets/images/Image1.jpg',
      preferredCommunity: 'gulshan',
      isAdmin: false,
      blocked: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 60)),
      blockedDate: DateTime.now().subtract(const Duration(days: 10)),
      blockedReason: 'Spam posting',
    ),

    // Bashundhara Users
    CommunityUser(
      userId: '6',
      username: 'Hassan Ahmed',
      email: 'hassan.ahmed@example.com',
      profileImage: 'assets/images/Image2.jpg',
      preferredCommunity: 'bashundhara',
      isAdmin: false,
      blocked: false,
      joinedDate: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  // Real join requests data - loaded from API
  List<JoinRequest> _joinRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _loadAdminCommunities();
  }

  Future<void> _loadAdminCommunities() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final communityProvider = Provider.of<CommunityProvider>(
        context,
        listen: false,
      );
      final adminCommunities = await communityProvider.fetchAdminCommunities(
        user.email,
      );

      setState(() {
        _communities =
            adminCommunities.map((c) => CommunityData.fromProvider(c)).toList();
        _isLoading = false;
      });

      // Load join requests for admin communities
      await _loadJoinRequests();

      _updateCommunityStats();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadJoinRequests() async {
    try {
      List<JoinRequest> allRequests = [];

      // Get current user email for admin authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        print('No user email found for admin authentication');
        return;
      }
      final adminEmail = user!.email!;

      // Get join requests for each admin community
      for (final community in _communities) {
        final requests = await _joinRequestService.getPendingJoinRequests(
          community.id,
          adminEmail: adminEmail,
        );
        for (final req in requests) {
          // Convert JoinRequestData to JoinRequest
          allRequests.add(
            JoinRequest(
              requestId: req.userId,
              userId: req.userId,
              username: req.username,
              email: req.userEmail,
              profileImage:
                  req.profileImage.isNotEmpty
                      ? req.profileImage
                      : 'assets/images/dummy.png',
              targetCommunity: community.name,
              requestDate: req.requestDate,
              message: req.message,
            ),
          );
        }
      }

      setState(() {
        _joinRequests = allRequests;
      });
    } catch (e) {
      print('Error loading join requests: $e');
      // Don't show error to user, just log it
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateCommunityStats() {
    for (var community in _communities) {
      // Calculate active members (total members minus any blocked members)
      // For now, we'll use the memberCount from Firestore
      // In a real implementation, you'd fetch user status from a separate collection
      community.activeMembers = community.members.length;

      // Blocked members - this would come from a user status collection in Firestore
      // For now, we'll use the mock blocked users count
      final communityUsers =
          _allUsers
              .where(
                (user) =>
                    user.preferredCommunity == community.id && !user.isAdmin,
              )
              .toList();
      community.blockedMembers =
          communityUsers.where((user) => user.blocked).length;
    }
  }

  void _showCommunityMembersModal(CommunityData community) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _CommunityMembersModal(
            community: community,
            allUsers: _allUsers,
            onUserAction:
                (action, user, {duration, reason}) => _handleUserAction(
                  action,
                  user,
                  duration: duration,
                  reason: reason,
                ),
          ),
    );
  }

  void _handleUserAction(
    UserAction action,
    CommunityUser user, {
    String? duration,
    String? reason,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.email == null) {
        _showErrorSnackBar('Admin authentication required');
        return;
      }

      final adminEmail = currentUser!.email!;
      bool success = false;

      // Find the community ID for this user
      final userCommunity = _communities.firstWhere(
        (community) => community.members.contains(user.email),
        orElse: () => _communities.first, // fallback to first community
      );

      switch (action) {
        case UserAction.block:
          if (duration == null || reason == null) {
            _showErrorSnackBar('Duration and reason are required for blocking');
            return;
          }

          String blockType;
          if (duration == 'permanent') {
            blockType = 'permanent';
          } else if (duration == 'indefinite') {
            blockType = 'indefinite';
          } else {
            blockType = 'temporary';
          }

          success = await _blockService.blockUserInCommunity(
            communityId: userCommunity.id,
            userEmail: user.email,
            adminEmail: adminEmail,
            blockType: blockType,
            duration: blockType == 'temporary' ? duration : null,
            reason: reason,
          );

          if (success) {
            setState(() {
              user.blocked = true;
              user.blockedDate = DateTime.now();
              user.blockedReason = reason;
              if (duration != 'indefinite' && duration != 'permanent') {
                user.blockedReason = '$reason (Blocked for $duration)';
              }
            });
          }
          break;

        case UserAction.unblock:
          success = await _blockService.unblockUserInCommunity(
            communityId: userCommunity.id,
            userEmail: user.email,
            adminEmail: adminEmail,
          );

          if (success) {
            setState(() {
              user.blocked = false;
              user.blockedDate = null;
              user.blockedReason = null;
            });
          }
          break;

        case UserAction.removeFromCommunity:
          success = await _blockService.removeUserFromCommunity(
            communityId: userCommunity.id,
            userEmail: user.email,
            adminEmail: adminEmail,
          );

          if (success) {
            setState(() {
              _allUsers.remove(user);
            });
          }
          break;

        case UserAction.permanentBlock:
          success = await _blockService.blockUserInCommunity(
            communityId: userCommunity.id,
            userEmail: user.email,
            adminEmail: adminEmail,
            blockType: 'permanent',
            reason: reason ?? 'Permanently banned by admin',
          );

          if (success) {
            setState(() {
              _allUsers.remove(user);
            });
          }
          break;
      }

      if (success) {
        _updateCommunityStats();
        _showSuccessSnackBar(action, user);
      } else {
        _showErrorSnackBar('Failed to ${action.name} user. Please try again.');
      }
    } catch (e) {
      print('Error in _handleUserAction: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  void _showSuccessSnackBar(UserAction action, CommunityUser user) {
    final message = switch (action) {
      UserAction.block => '${user.username} has been blocked',
      UserAction.unblock => '${user.username} has been unblocked',
      UserAction.removeFromCommunity =>
        '${user.username} has been removed from community',
      UserAction.permanentBlock =>
        '${user.username} has been permanently banned and reported',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            action == UserAction.unblock
                ? Colors.green
                : action == UserAction.permanentBlock
                ? Colors.red[700]
                : Colors.orange,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[700]),
    );
  }

  void _handleJoinRequest(JoinRequest request, bool accept) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Admin email not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Find the community ID from the community name
      final community = _communities.firstWhere(
        (c) => c.name == request.targetCommunity,
        orElse: () => throw Exception('Community not found'),
      );

      Map<String, dynamic> result;
      if (accept) {
        result = await _joinRequestService.approveJoinRequest(
          adminEmail: user!.email!,
          communityId: community.id,
          userEmail: request.email,
        );
      } else {
        result = await _joinRequestService.rejectJoinRequest(
          adminEmail: user!.email!,
          communityId: community.id,
          userEmail: request.email,
        );
      }

      if (result['success'] == true) {
        setState(() {
          _joinRequests.remove(request);
        });

        final message =
            accept
                ? '${request.username} has been added to ${request.targetCommunity}'
                : '${request.username}\'s request has been declined';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: accept ? Colors.green : Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to process request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error handling join request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatsOverview() {
    final totalMembers = _communities.fold(
      0,
      (sum, community) => sum + community.members.length,
    );
    final totalJoinRequests = _communities.fold(
      0,
      (sum, community) => sum + community.joinRequests.length,
    );
    final totalCommunities = _communities.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF0E7490)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.3),
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
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Admin Communities Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Communities',
                  totalCommunities.toString(),
                  Icons.location_city,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Members',
                  totalMembers.toString(),
                  Icons.people,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Join Requests',
                  totalJoinRequests.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
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
    );
  }

  Widget _buildCommunityCard(CommunityData community) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child:
              community.imageUrl != null
                  ? Image.network(
                    community.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/dummy.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                  : Image.asset(
                    'assets/images/dummy.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
        ),
        title: Text(
          community.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              community.location,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMemberBadge(
                  '${community.members.length} Members',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                if (community.joinRequests.isNotEmpty)
                  _buildMemberBadge(
                    '${community.joinRequests.length} Requests',
                    Colors.orange,
                  ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF06B6D4),
          size: 16,
        ),
        onTap: () => _showCommunityMembersModal(community),
      ),
    );
  }

  Widget _buildMemberBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildJoinRequestCard(JoinRequest request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  request.profileImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Wants to join ${request.targetCommunity}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimeAgo(request.requestDate),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          if (request.message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                request.message,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleJoinRequest(request, false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleJoinRequest(request, true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06B6D4),
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
                Icons.people_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Community Users',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              icon: const Icon(Icons.groups, size: 20),
              text: 'Community Members',
            ),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.pending_actions, size: 20),
                  if (_joinRequests.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '${_joinRequests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              text: 'Join Requests',
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                ),
              )
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading communities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAdminCommunities,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : _communities.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Admin Communities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You are not an admin of any communities yet.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildStatsOverview(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Community Members Tab
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _communities.length,
                                  itemBuilder: (context, index) {
                                    return _buildCommunityCard(
                                      _communities[index],
                                    );
                                  },
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                          // Join Requests Tab
                          _joinRequests.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending requests',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'New community join requests will appear here',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _joinRequests.length,
                                      itemBuilder: (context, index) {
                                        return _buildJoinRequestCard(
                                          _joinRequests[index],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 30),
                                  ],
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

// Community Members Modal Widget
class _CommunityMembersModal extends StatefulWidget {
  final CommunityData community;
  final List<CommunityUser> allUsers;
  final Function(UserAction, CommunityUser, {String? duration, String? reason})
  onUserAction;

  const _CommunityMembersModal({
    required this.community,
    required this.allUsers,
    required this.onUserAction,
  });

  @override
  State<_CommunityMembersModal> createState() => _CommunityMembersModalState();
}

class _CommunityMembersModalState extends State<_CommunityMembersModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Real member data from Firestore
  List<CommunityUser> _realMembers = [];
  bool _isLoadingMembers = true;
  String? _membersError;
  final CommunityService _communityService = CommunityService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCommunityMembers();
  }

  Future<void> _loadCommunityMembers() async {
    try {
      setState(() {
        _isLoadingMembers = true;
        _membersError = null;
      });

      final members = await _communityService.getCommunityMembers(
        widget.community.id,
      );

      setState(() {
        _realMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _membersError = e.toString();
        _isLoadingMembers = false;
        // Use mock data as fallback
        _realMembers =
            widget.allUsers
                .where(
                  (user) =>
                      user.preferredCommunity == widget.community.id &&
                      !user.isAdmin,
                )
                .toList();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityUser> _getFilteredUsers(bool showBlocked) {
    // Use real Firestore data if available, otherwise fallback to mock data
    final sourceUsers = _isLoadingMembers ? widget.allUsers : _realMembers;

    final communityUsers =
        sourceUsers
            .where(
              (user) =>
                  (_isLoadingMembers
                      ? user.preferredCommunity == widget.community.id &&
                          !user.isAdmin
                      : true // Real data is already filtered by community
                      ) &&
                  user.blocked == showBlocked,
            )
            .toList();

    if (_searchQuery.isEmpty) return communityUsers;

    return communityUsers
        .where(
          (user) =>
              user.username.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showBlockDialog(CommunityUser user) {
    showDialog(
      context: context,
      builder:
          (context) => _BlockUserDialog(
            user: user,
            onBlock: (duration, reason) {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close modal

              // Check if it's a permanent block
              if (duration == 'permanent') {
                // Permanent block = complete removal
                widget.onUserAction(
                  UserAction.permanentBlock,
                  user,
                  reason: reason,
                );
              } else {
                // Temporary/Indefinite block = move to blocked tab
                widget.onUserAction(
                  UserAction.block,
                  user,
                  duration: duration,
                  reason: reason,
                );
              }
            },
          ),
    );
  }

  void _showUnblockDialog(CommunityUser user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unblock User'),
            content: Text('Are you sure you want to unblock ${user.username}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Close modal
                  widget.onUserAction(UserAction.unblock, user);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Unblock',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showRemoveDialog(CommunityUser user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove from Community'),
            content: Text(
              'Are you sure you want to remove ${user.username} from this community?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Close modal
                  widget.onUserAction(UserAction.removeFromCommunity, user);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildUserTile(CommunityUser user, bool isBlocked) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.red.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlocked ? Colors.red.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              user.profileImage,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${_formatDate(user.joinedDate)}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isBlocked && user.blockedReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reason: ${user.blockedReason}',
                    style: const TextStyle(fontSize: 10, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          if (isBlocked)
            IconButton(
              onPressed: () => _showUnblockDialog(user),
              icon: const Icon(Icons.lock_open, color: Colors.green, size: 18),
              tooltip: 'Unblock',
            )
          else ...[
            IconButton(
              onPressed: () => _showRemoveDialog(user),
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.orange,
                size: 18,
              ),
              tooltip: 'Remove from community',
            ),
            IconButton(
              onPressed: () => _showBlockDialog(user),
              icon: const Icon(Icons.block, color: Colors.red, size: 18),
              tooltip: 'Block user',
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = _getFilteredUsers(false);
    final blockedUsers = _getFilteredUsers(true);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      widget.community.imageUrl != null
                          ? Image.network(
                            widget.community.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/dummy.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                          : Image.asset(
                            'assets/images/dummy.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.community.name} Members',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoadingMembers
                            ? 'Loading members...'
                            : '${_realMembers.length} total members • ${activeUsers.length} active • ${blockedUsers.length} blocked',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Loading indicator for members
          if (_isLoadingMembers)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF06B6D4),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading community members...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (_membersError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Using cached data instead',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCommunityMembers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF06B6D4),
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF06B6D4)),
                  ),
                ),
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text('Active (${activeUsers.length})'),
                  ),
                  Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Text('Blocked (${blockedUsers.length})'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active Users
                  activeUsers.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No users match your search'
                                  : 'No active members',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: activeUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserTile(activeUsers[index], false);
                        },
                      ),

                  // Blocked Users
                  blockedUsers.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.block,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No blocked users match your search'
                                  : 'No blocked users',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: blockedUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserTile(blockedUsers[index], true);
                        },
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Updated CommunityData to include additional fields for admin management
class CommunityData {
  final String id;
  final String name;
  final String description;
  final String location;
  final String? imageUrl;
  final List<String> admins;
  final List<String> members;
  final List<String> joinRequests;
  final int memberCount;
  final List<String> tags;
  final DateTime? joinDate;
  final String? recentActivity;
  int activeMembers;
  int blockedMembers;

  CommunityData({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.admins,
    required this.members,
    required this.joinRequests,
    required this.memberCount,
    required this.tags,
    this.joinDate,
    this.recentActivity,
    required this.activeMembers,
    required this.blockedMembers,
  });

  // Create from provider CommunityData
  factory CommunityData.fromProvider(dynamic providerCommunity) {
    return CommunityData(
      id: providerCommunity.id,
      name: providerCommunity.name,
      description: providerCommunity.description,
      location: providerCommunity.location,
      imageUrl: providerCommunity.imageUrl,
      admins: List<String>.from(providerCommunity.admins ?? []),
      members: List<String>.from(providerCommunity.members ?? []),
      joinRequests: List<String>.from(providerCommunity.joinRequests ?? []),
      memberCount: providerCommunity.memberCount,
      tags: List<String>.from(providerCommunity.tags ?? []),
      joinDate: providerCommunity.joinDate,
      recentActivity: providerCommunity.recentActivity,
      activeMembers: 0, // Will be calculated dynamically
      blockedMembers: 0, // Will be calculated dynamically
    );
  }

  String get image => imageUrl ?? 'assets/images/dummy.png';
}

class JoinRequest {
  final String requestId;
  final String userId;
  final String username;
  final String email;
  final String profileImage;
  final String targetCommunity;
  final DateTime requestDate;
  final String message;

  JoinRequest({
    required this.requestId,
    required this.userId,
    required this.username,
    required this.email,
    required this.profileImage,
    required this.targetCommunity,
    required this.requestDate,
    required this.message,
  });
}

// Block User Dialog Widget
class _BlockUserDialog extends StatefulWidget {
  final CommunityUser user;
  final Function(String duration, String reason) onBlock;

  const _BlockUserDialog({required this.user, required this.onBlock});

  @override
  State<_BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<_BlockUserDialog> {
  String _selectedDuration = '1 day';
  String _customDuration = '';
  String _blockReason = '';
  bool _showCustomDuration = false;

  final List<String> _fixedDurations = [
    '1 day',
    '3 days',
    '1 week',
    '2 weeks',
    '1 month',
    '3 months',
    'Custom',
    'Indefinite',
    'Permanent',
  ];

  final List<String> _commonReasons = [
    'Inappropriate behavior',
    'Spam posting',
    'Harassment',
    'Violation of community guidelines',
    'Offensive language',
    'Fake information',
    'Other',
  ];

  void _handleBlock() {
    if (_blockReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for blocking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDuration == 'Custom' && _customDuration.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify custom duration'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration =
        _selectedDuration == 'Custom'
            ? _customDuration
            : _selectedDuration.toLowerCase();
    widget.onBlock(duration, _blockReason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.block, color: Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Block ${widget.user.username}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will prevent ${widget.user.username} from participating in community activities.',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Block Duration Section
            const Text(
              'Block Duration',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDuration,
                  isExpanded: true,
                  items:
                      _fixedDurations.map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text(
                            duration,
                            style: TextStyle(
                              color:
                                  duration == 'Permanent'
                                      ? Colors.red
                                      : Colors.black,
                              fontWeight:
                                  duration == 'Permanent'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDuration = value!;
                      _showCustomDuration = value == 'Custom';
                    });
                  },
                ),
              ),
            ),

            // Custom Duration Input
            if (_showCustomDuration) ...[
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => _customDuration = value,
                decoration: InputDecoration(
                  labelText: 'Custom Duration',
                  hintText: 'e.g., 5 days, 2 months',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.schedule),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Block Reason Section
            const Text(
              'Reason for Blocking',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Common Reasons Chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children:
                  _commonReasons.map((reason) {
                    final isSelected = _blockReason == reason;
                    return GestureDetector(
                      onTap: () => setState(() => _blockReason = reason),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF06B6D4)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF06B6D4)
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            const SizedBox(height: 12),

            // Custom Reason Input
            TextField(
              onChanged: (value) => _blockReason = value,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Custom Reason (Optional)',
                hintText: 'Provide additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),

            if (_selectedDuration == 'Permanent') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Permanent block will remove the user from the community and report them to authorities.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleBlock,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _selectedDuration == 'Permanent' ? Colors.red[700] : Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _selectedDuration == 'Permanent' ? 'Permanent Block' : 'Block User',
          ),
        ),
      ],
    );
  }
}

enum UserAction { block, unblock, removeFromCommunity, permanentBlock }
