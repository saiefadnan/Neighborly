import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommunityListPage extends StatefulWidget {
  const CommunityListPage({super.key});

  @override
  State<CommunityListPage> createState() => _CommunityListPageState();
}

class _CommunityListPageState extends State<CommunityListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedCommunities = {};

  final List<Community> _myCommunities = [
    Community(
      name: 'Dhanmondi',
      memberCount: 1248,
      description:
          'A vibrant residential area known for its cultural heritage and green spaces.',
      location: 'Dhaka, Bangladesh',
      joinDate: 'Joined 6 months ago',
      moderators: ['Rashid Ahmed', 'Fatima Khan'],
      recentActivity: 'Last active 2 hours ago',
      tags: ['Residential', 'Cultural', 'Safe'],
      image: 'assets/images/Image1.jpg',
    ),
    Community(
      name: 'Gulshan',
      memberCount: 2156,
      description:
          'Upscale commercial and residential area with modern amenities.',
      location: 'Dhaka, Bangladesh',
      joinDate: 'Joined 1 year ago',
      moderators: ['Karim Hassan', 'Nadia Sultana'],
      recentActivity: 'Last active 1 hour ago',
      tags: ['Commercial', 'Upscale', 'Modern'],
      image: 'assets/images/Image2.jpg',
    ),
  ];

  final List<Community> _otherCommunities = [
    Community(
      name: 'Mohammadpur',
      memberCount: 987,
      description:
          'Densely populated residential area with rich local culture.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Abdul Rahman', 'Salma Begum'],
      recentActivity: 'Last active 30 minutes ago',
      tags: ['Residential', 'Cultural', 'Busy'],
      image: 'assets/images/Image3.jpg',
    ),
    Community(
      name: 'Mirpur',
      memberCount: 1543,
      description:
          'Large residential area known for its diversity and community spirit.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Mahmud Ali', 'Rohana Khatun'],
      recentActivity: 'Last active 15 minutes ago',
      tags: ['Residential', 'Diverse', 'Active'],
      image: 'assets/images/Image1.jpg',
    ),
    Community(
      name: 'Baridhara',
      memberCount: 756,
      description: 'Diplomatic zone with embassies and upscale residences.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Tariq Ahmed', 'Ayesha Rahman'],
      recentActivity: 'Last active 1 hour ago',
      tags: ['Diplomatic', 'Upscale', 'Secure'],
      image: 'assets/images/Image2.jpg',
    ),
    Community(
      name: 'Rampura',
      memberCount: 834,
      description: 'Growing residential area with good connectivity.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Habib Khan', 'Nasreen Akter'],
      recentActivity: 'Last active 45 minutes ago',
      tags: ['Residential', 'Growing', 'Connected'],
      image: 'assets/images/Image3.jpg',
    ),
    Community(
      name: 'Bashundhara',
      memberCount: 1876,
      description: 'Modern planned residential area with excellent facilities.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Rafiq Islam', 'Shahnaz Parveen'],
      recentActivity: 'Last active 20 minutes ago',
      tags: ['Modern', 'Planned', 'Facilities'],
      image: 'assets/images/Image1.jpg',
    ),
    Community(
      name: 'Kakrail',
      memberCount: 456,
      description:
          'Central location with mix of residential and commercial spaces.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Aminul Haque', 'Ruma Khatun'],
      recentActivity: 'Last active 3 hours ago',
      tags: ['Central', 'Mixed', 'Accessible'],
      image: 'assets/images/Image2.jpg',
    ),
    Community(
      name: 'Malibagh',
      memberCount: 623,
      description:
          'Historic area with traditional architecture and local markets.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Nazrul Islam', 'Rabeya Sultana'],
      recentActivity: 'Last active 2 hours ago',
      tags: ['Historic', 'Traditional', 'Markets'],
      image: 'assets/images/Image3.jpg',
    ),
    Community(
      name: 'Farmgate',
      memberCount: 1234,
      description: 'Commercial hub with excellent transport connectivity.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Selim Reza', 'Maksuda Begum'],
      recentActivity: 'Last active 1 hour ago',
      tags: ['Commercial', 'Transport', 'Hub'],
      image: 'assets/images/Image1.jpg',
    ),
    Community(
      name: 'Kathalbagan',
      memberCount: 567,
      description: 'Residential area known for its educational institutions.',
      location: 'Dhaka, Bangladesh',
      moderators: ['Mostofa Kamal', 'Shireen Akter'],
      recentActivity: 'Last active 4 hours ago',
      tags: ['Residential', 'Educational', 'Peaceful'],
      image: 'assets/images/Image2.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _joinCommunity(Community community) {
    HapticFeedback.lightImpact();
    setState(() {
      _otherCommunities.remove(community);
      community.joinDate = 'Just joined';
      _myCommunities.add(community);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined ${community.name} community!'),
        backgroundColor: const Color(0xFF71BB7B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              onPressed: () {
                setState(() {
                  _myCommunities.remove(community);
                  community.joinDate = null;
                  _otherCommunities.add(community);
                });
                Navigator.of(context).pop();
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
        title: const Text(
          'Communities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group),
                  const SizedBox(width: 8),
                  Text('My Communities (${_myCommunities.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.explore),
                  const SizedBox(width: 8),
                  Text('Explore (${_otherCommunities.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCommunityList(_myCommunities, true),
                _buildCommunityList(_otherCommunities, false),
              ],
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
