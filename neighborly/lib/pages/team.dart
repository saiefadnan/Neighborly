import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  // Community data - same as AdminCommunityManagementPage
  final List<CommunityAdminData> _communities = [
    CommunityAdminData(
      id: '1',
      name: 'Dhanmondi',
      image: 'assets/images/Image1.jpg',
      location: 'Dhaka, Bangladesh',
      totalMembers: 1248,
      admins: [
        AdminUser(
          userId: '1',
          name: 'Sarah Ahmed',
          email: 'sarah.ahmed@example.com',
          profileImage: 'assets/images/Image1.jpg',
          role: 'Community Admin',
          addedDate: DateTime.now().subtract(const Duration(days: 30)),
          addedBy: 'Super Admin',
        ),
        AdminUser(
          userId: '2',
          name: 'Karim Hassan',
          email: 'karim.hassan@example.com',
          profileImage: 'assets/images/Image2.jpg',
          role: 'Community Admin',
          addedDate: DateTime.now().subtract(const Duration(days: 15)),
          addedBy: 'Sarah Ahmed',
        ),
      ],
    ),
    CommunityAdminData(
      id: '2',
      name: 'Gulshan',
      image: 'assets/images/Image2.jpg',
      location: 'Dhaka, Bangladesh',
      totalMembers: 2156,
      admins: [
        AdminUser(
          userId: '3',
          name: 'Fatima Khan',
          email: 'fatima.khan@example.com',
          profileImage: 'assets/images/Image3.jpg',
          role: 'Community Admin',
          addedDate: DateTime.now().subtract(const Duration(days: 45)),
          addedBy: 'Super Admin',
        ),
      ],
    ),
    CommunityAdminData(
      id: '3',
      name: 'Bashundhara',
      image: 'assets/images/Image3.jpg',
      location: 'Dhaka, Bangladesh',
      totalMembers: 1876,
      admins: [
        AdminUser(
          userId: '4',
          name: 'Abdul Rahman',
          email: 'abdul.rahman@example.com',
          profileImage: 'assets/images/Image1.jpg',
          role: 'Community Admin',
          addedDate: DateTime.now().subtract(const Duration(days: 20)),
          addedBy: 'Super Admin',
        ),
        AdminUser(
          userId: '5',
          name: 'Nadia Islam',
          email: 'nadia.islam@example.com',
          profileImage: 'assets/images/Image2.jpg',
          role: 'Community Admin',
          addedDate: DateTime.now().subtract(const Duration(days: 10)),
          addedBy: 'Abdul Rahman',
        ),
      ],
    ),
  ];

  // Mock user database for search functionality
  final List<FirebaseUser> _availableUsers = [
    FirebaseUser(
      userId: '6',
      name: 'Ali Rahman',
      email: 'ali.rahman@example.com',
      profileImage: 'assets/images/dummy.png',
      communityMemberships: ['1', '2'], // Member of Dhanmondi and Gulshan
    ),
    FirebaseUser(
      userId: '7',
      name: 'Maria Jose',
      email: 'maria.jose@example.com',
      profileImage: 'assets/images/Image1.jpg',
      communityMemberships: ['2', '3'], // Member of Gulshan and Bashundhara
    ),
    FirebaseUser(
      userId: '8',
      name: 'Hassan Ahmed',
      email: 'hassan.ahmed@example.com',
      profileImage: 'assets/images/Image3.jpg',
      communityMemberships: ['1'], // Member of Dhanmondi only
    ),
    FirebaseUser(
      userId: '9',
      name: 'Rashida Begum',
      email: 'rashida.begum@example.com',
      profileImage: 'assets/images/Image2.jpg',
      communityMemberships: ['3'], // Member of Bashundhara only
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
    _searchController.dispose();
    super.dispose();
  }

  void _addAdmin(String communityId, FirebaseUser user) {
    setState(() {
      final communityIndex = _communities.indexWhere(
        (c) => c.id == communityId,
      );
      if (communityIndex != -1) {
        // Check if user is already an admin
        final isAlreadyAdmin = _communities[communityIndex].admins.any(
          (admin) => admin.userId == user.userId,
        );

        if (!isAlreadyAdmin) {
          _communities[communityIndex].admins.add(
            AdminUser(
              userId: user.userId,
              name: user.name,
              email: user.email,
              profileImage: user.profileImage,
              role: 'Community Admin',
              addedDate: DateTime.now(),
              addedBy:
                  'Current Admin', // In real app, this would be current user
            ),
          );
        }
      }
    });
  }

  void _removeAdmin(String communityId, String userId) {
    setState(() {
      final communityIndex = _communities.indexWhere(
        (c) => c.id == communityId,
      );
      if (communityIndex != -1) {
        _communities[communityIndex].admins.removeWhere(
          (admin) => admin.userId == userId,
        );
      }
    });
  }

  void _showAddAdminModal(CommunityAdminData community) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _AddAdminModal(
            community: community,
            availableUsers: _availableUsers,
            onAddAdmin: (user) => _addAdmin(community.id, user),
          ),
    );
  }

  Widget _buildStatsOverview() {
    final totalAdmins = _communities.fold(
      0,
      (sum, community) => sum + community.admins.length,
    );
    final totalCommunities = _communities.length;
    final activeCommunities =
        _communities.where((c) => c.admins.isNotEmpty).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFFB45309)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
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
                'Community Admins Overview',
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
                  'Total Admins',
                  totalAdmins.toString(),
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Communities',
                  totalCommunities.toString(),
                  Icons.location_city,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  activeCommunities.toString(),
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
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

  Widget _buildCommunityCard(CommunityAdminData community) {
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
      child: Column(
        children: [
          // Community Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    community.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${community.totalMembers} members • ${community.location}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${community.admins.length} Admin${community.admins.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAdminModal(community),
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Admins List
          if (community.admins.isNotEmpty)
            Column(
              children:
                  community.admins
                      .map((admin) => _buildAdminTile(community.id, admin))
                      .toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No admins assigned',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add an admin to manage this community',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminTile(String communityId, AdminUser admin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              admin.profileImage,
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
                  admin.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  admin.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  'Added ${_formatDate(admin.addedDate)} by ${admin.addedBy}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              admin.role,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showRemoveAdminDialog(communityId, admin),
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.red,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveAdminDialog(String communityId, AdminUser admin) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Admin'),
            content: Text(
              'Are you sure you want to remove ${admin.name} as an admin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeAdmin(communityId, admin.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${admin.name} removed as admin'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF59E0B),
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
                Icons.group_work_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Community Admins',
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsOverview(),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _communities.length,
                itemBuilder: (context, index) {
                  return _buildCommunityCard(_communities[index]);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Add Admin Modal Widget
class _AddAdminModal extends StatefulWidget {
  final CommunityAdminData community;
  final List<FirebaseUser> availableUsers;
  final Function(FirebaseUser) onAddAdmin;

  const _AddAdminModal({
    required this.community,
    required this.availableUsers,
    required this.onAddAdmin,
  });

  @override
  State<_AddAdminModal> createState() => _AddAdminModalState();
}

class _AddAdminModalState extends State<_AddAdminModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<FirebaseUser> _getEligibleUsers() {
    // Filter users who are members of this community and not already admins
    final currentAdminIds =
        widget.community.admins.map((admin) => admin.userId).toSet();

    return widget.availableUsers.where((user) {
      final isCommunityMember = user.communityMemberships.contains(
        widget.community.id,
      );
      final isNotAlreadyAdmin = !currentAdminIds.contains(user.userId);
      final matchesSearch =
          _searchQuery.isEmpty ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return isCommunityMember && isNotAlreadyAdmin && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eligibleUsers = _getEligibleUsers();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                  child: Image.asset(
                    widget.community.image,
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
                        'Add Admin to ${widget.community.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search community members by email',
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

          const SizedBox(height: 20),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by email or name...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFF59E0B)),
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
                  borderSide: const BorderSide(color: Color(0xFFF59E0B)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Users List
          Expanded(
            child:
                eligibleUsers.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No eligible members found'
                                : 'No members match your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Members must belong to this community to become admins',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: eligibleUsers.length,
                      itemBuilder: (context, index) {
                        final user = eligibleUsers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                user.profileImage,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(user.email),
                            trailing: ElevatedButton(
                              onPressed: () {
                                widget.onAddAdmin(user);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${user.name} added as admin',
                                    ),
                                    backgroundColor: const Color(0xFFF59E0B),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Add'),
                            ),
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

// Data Models
class CommunityAdminData {
  final String id;
  final String name;
  final String image;
  final String location;
  final int totalMembers;
  final List<AdminUser> admins;

  CommunityAdminData({
    required this.id,
    required this.name,
    required this.image,
    required this.location,
    required this.totalMembers,
    required this.admins,
  });
}

class AdminUser {
  final String userId;
  final String name;
  final String email;
  final String profileImage;
  final String role;
  final DateTime addedDate;
  final String addedBy;

  AdminUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.role,
    required this.addedDate,
    required this.addedBy,
  });
}

class FirebaseUser {
  final String userId;
  final String name;
  final String email;
  final String profileImage;
  final List<String> communityMemberships;

  FirebaseUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.communityMemberships,
  });
}
