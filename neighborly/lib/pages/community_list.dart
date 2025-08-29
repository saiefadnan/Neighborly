import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'announcements.dart';
import '../providers/community_provider.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedCommunities = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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

    _headerAnimationController.forward();

    // Initialize communities data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      provider.initializeCommunities();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Convert CommunityData to Community for UI compatibility
  Community _convertToLegacyCommunity(CommunityData data) {
    return Community(
      name: data.name,
      memberCount: data.memberCount,
      description: data.description,
      location: data.location,
      joinDate:
          data.joinDate?.toString() ??
          (data.members.isNotEmpty ? 'Joined' : null),
      moderators: data.admins,
      recentActivity: data.recentActivity ?? 'Active recently',
      tags: data.tags,
      image: data.imageUrl ?? 'assets/images/Image1.jpg', // fallback image
    );
  }

  // Build community list using provider data
  Widget _buildCommunityListFromProvider(
    List<CommunityData> communities,
    bool isMyCommunity,
  ) {
    final legacyCommunities =
        communities.map(_convertToLegacyCommunity).toList();
    return _buildCommunityList(legacyCommunities, isMyCommunity);
  }

  List<Community> _getFilteredCommunities(List<Community> communities) {
    if (_searchQuery.isEmpty) return communities;
    return communities
        .where(
          (community) =>
              community.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              community.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              community.tags.any(
                (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
              ),
        )
        .toList();
  }

  void _joinCommunity(Community community) async {
    HapticFeedback.lightImpact();

    final provider = Provider.of<CommunityProvider>(context, listen: false);

    // Find the community ID by name from the all communities list
    final communityData = provider.allCommunities.firstWhere(
      (c) => c.name == community.name,
      orElse: () => throw Exception('Community not found'),
    );

    final success = await provider.joinCommunity(communityData.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined ${community.name} community!'),
          backgroundColor: const Color(0xFF71BB7B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join ${community.name}. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _leaveCommunity(Community community) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Leave Community'),
          content: Text('Are you sure you want to leave ${community.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = Provider.of<CommunityProvider>(
                  context,
                  listen: false,
                );

                // Find the community ID by name from the my communities list
                final communityData = provider.myCommunities.firstWhere(
                  (c) => c.name == community.name,
                  orElse: () => throw Exception('Community not found'),
                );

                final success = await provider.leaveCommunity(communityData.id);

                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Left ${community.name} community'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to leave ${community.name}. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  void _toggleExpansion(String communityName) {
    setState(() {
      if (_expandedCommunities.contains(communityName)) {
        _expandedCommunities.remove(communityName);
      } else {
        _expandedCommunities.add(communityName);
      }
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search communities...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF71BB7B)),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey),
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(Community community, bool isMyCommunity) {
    final isExpanded = _expandedCommunities.contains(community.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Community Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    community.image,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),
                // Community Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              community.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMyCommunity
                                      ? const Color(0xFF71BB7B).withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isMyCommunity ? 'Member' : 'Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isMyCommunity
                                        ? const Color(0xFF71BB7B)
                                        : Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${community.memberCount} members • ${community.location}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (isMyCommunity && community.joinDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          community.joinDate!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF71BB7B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        community.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D6D7E),
                          height: 1.3,
                        ),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  community.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF71BB7B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF71BB7B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // Expanded Details
          if (isExpanded) ...[
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Moderators: ${community.moderators.join(", ")}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        community.recentActivity,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Details Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleExpansion(community.name),
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(isExpanded ? 'Less Details' : 'More Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF71BB7B),
                      side: const BorderSide(color: Color(0xFF71BB7B)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Join/Leave Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (isMyCommunity) {
                        _leaveCommunity(community);
                      } else {
                        _joinCommunity(community);
                      }
                    },
                    icon: Icon(
                      isMyCommunity ? Icons.exit_to_app : Icons.add,
                      size: 18,
                    ),
                    label: Text(isMyCommunity ? 'Leave' : 'Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isMyCommunity ? Colors.red : const Color(0xFF71BB7B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityList(List<Community> communities, bool isMyCommunity) {
    final filteredCommunities = _getFilteredCommunities(communities);

    if (filteredCommunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyCommunity ? Icons.group_off : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isMyCommunity
                  ? 'No communities joined yet'
                  : _searchQuery.isEmpty
                  ? 'No communities available'
                  : 'No communities found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isMyCommunity) ...[
              const SizedBox(height: 8),
              Text(
                'Explore other communities to join!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredCommunities.length,
      itemBuilder: (context, index) {
        return _buildCommunityCard(filteredCommunities[index], isMyCommunity);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
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
                      Icons.people,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Communities',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ), //announcements icon connected to announcement page
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement, color: Colors.white),
            tooltip: 'Announcements',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Announcements'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child:
                            AnnouncementsList(), // Only the list, not the posting UI
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group),
                      const SizedBox(width: 8),
                      Text('My Communities (${provider.myCommunities.length})'),
                    ],
                  ),
                );
              },
            ),
            Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.explore),
                      const SizedBox(width: 8),
                      Text('Explore (${provider.availableCommunities.length})'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Consumer<CommunityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCommunityListFromProvider(
                      provider.myCommunities,
                      true,
                    ),
                    _buildCommunityListFromProvider(
                      provider.availableCommunities,
                      false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Community {
  final String name;
  final int memberCount;
  final String description;
  final String location;
  String? joinDate;
  final List<String> moderators;
  final String recentActivity;
  final List<String> tags;
  final String image;

  Community({
    required this.name,
    required this.memberCount,
    required this.description,
    required this.location,
    this.joinDate,
    required this.moderators,
    required this.recentActivity,
    required this.tags,
    required this.image,
  });
}
