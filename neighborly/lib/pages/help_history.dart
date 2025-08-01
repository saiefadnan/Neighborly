import 'package:flutter/material.dart';
import 'package:neighborly/models/feedback_models.dart';
import 'package:neighborly/pages/report_feedback.dart';

class HelpHistoryPage extends StatefulWidget {
  const HelpHistoryPage({super.key});

  @override
  State<HelpHistoryPage> createState() => _HelpHistoryPageState();
}

class _HelpHistoryPageState extends State<HelpHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFilter = 'All Time';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _timeFilters = [
    'All Time',
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];
  final List<String> _statusFilters = [
    'All',
    'Completed',
    'In Progress',
    'Cancelled',
  ];

  // Sample data for help provided by user
  final List<HelpHistory> _helpProvided = [
    HelpHistory(
      id: '1',
      title: 'Emergency Medical Help',
      description: 'Helped elderly neighbor during medical emergency',
      helpType: 'Medical',
      status: 'Completed',
      requesterName: 'Sarah Ahmed',
      requesterImage: 'assets/images/Image1.jpg',
      location: 'Dhanmondi 15, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(days: 2)),
      duration: '45 minutes',
      rating: 5,
      feedback:
          'Amazing help! Ali was there immediately when I needed help most. Very grateful.',
      helpValuePoints: 50,
    ),
    HelpHistory(
      id: '2',
      title: 'Grocery Shopping Help',
      description: 'Bought groceries for sick neighbor',
      helpType: 'Grocery',
      status: 'Completed',
      requesterName: 'Fatima Khan',
      requesterImage: 'assets/images/Image3.jpg',
      location: 'Dhanmondi 27, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(days: 5)),
      duration: '1 hour 20 minutes',
      rating: 4,
      feedback:
          'Very helpful and brought everything I needed. Thank you so much!',
      helpValuePoints: 25,
    ),
    HelpHistory(
      id: '3',
      title: 'Furniture Moving',
      description: 'Helped move furniture to 4th floor',
      helpType: 'Shifting Furniture',
      status: 'Completed',
      requesterName: 'Abdul Rahman',
      requesterImage: 'assets/images/Image1.jpg',
      location: 'Bashundhara R/A, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(days: 12)),
      duration: '2 hours 15 minutes',
      rating: 5,
      feedback:
          'Strong and reliable help. Made the moving process so much easier!',
      helpValuePoints: 40,
    ),
    HelpHistory(
      id: '4',
      title: 'Route Guidance',
      description: 'Provided directions to new clinic',
      helpType: 'Route',
      status: 'In Progress',
      requesterName: 'Maria Jose',
      requesterImage: 'assets/images/Image2.jpg',
      location: 'Gulshan 2, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(hours: 3)),
      duration: 'Ongoing',
      rating: null,
      feedback: null,
      helpValuePoints: 0,
    ),
  ];

  // Sample data for help received by user
  final List<HelpHistory> _helpReceived = [
    HelpHistory(
      id: '5',
      title: 'Pet Care While Away',
      description: 'Someone took care of my cat while I was traveling',
      helpType: 'Pet Care',
      status: 'Completed',
      requesterName: 'Ali Rahman', // Current user
      requesterImage: 'assets/images/dummy.png',
      helperName: 'Nadia Islam',
      helperImage: 'assets/images/Image2.jpg',
      location: 'Dhanmondi 15, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(days: 15)),
      duration: '3 days',
      rating: 5,
      feedback:
          'I provided: Excellent care! My cat was happy and healthy when I returned.',
      helpValuePoints: 35,
      isReceived: true,
    ),
    HelpHistory(
      id: '6',
      title: 'Math Tutoring Help',
      description: 'Got tutoring help for my son',
      helpType: 'Education',
      status: 'Completed',
      requesterName: 'Ali Rahman',
      requesterImage: 'assets/images/dummy.png',
      helperName: 'Dr. Rashid Ahmed',
      helperImage: 'assets/images/Image1.jpg',
      location: 'Dhanmondi 15, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(days: 8)),
      duration: '2 weeks',
      rating: 4,
      feedback:
          'I provided: Great teacher! My son improved a lot in mathematics.',
      helpValuePoints: 60,
      isReceived: true,
    ),
    HelpHistory(
      id: '7',
      title: 'Car Repair Guidance',
      description: 'Got help fixing my car',
      helpType: 'Repair',
      status: 'In Progress',
      requesterName: 'Ali Rahman',
      requesterImage: 'assets/images/dummy.png',
      helperName: 'Karim Hassan',
      helperImage: 'assets/images/Image3.jpg',
      location: 'Dhanmondi 15, Dhaka',
      dateCompleted: DateTime.now().subtract(Duration(hours: 6)),
      duration: 'Ongoing',
      rating: null,
      feedback: null,
      helpValuePoints: 0,
      isReceived: true,
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

  List<HelpHistory> _getFilteredHistory(List<HelpHistory> history) {
    return history.where((help) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          help.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          help.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (help.helperName?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false) ||
          help.requesterName.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus =
          _selectedStatusFilter == 'All' ||
          help.status == _selectedStatusFilter;

      bool matchesTime = true;
      if (_selectedTimeFilter != 'All Time') {
        DateTime now = DateTime.now();
        DateTime filterDate;
        switch (_selectedTimeFilter) {
          case 'This Week':
            filterDate = now.subtract(Duration(days: 7));
            break;
          case 'This Month':
            filterDate = now.subtract(Duration(days: 30));
            break;
          case 'Last 3 Months':
            filterDate = now.subtract(Duration(days: 90));
            break;
          case 'This Year':
            filterDate = now.subtract(Duration(days: 365));
            break;
          default:
            filterDate = DateTime(2000);
        }
        matchesTime = help.dateCompleted.isAfter(filterDate);
      }

      return matchesSearch && matchesStatus && matchesTime;
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getHelpTypeIcon(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Icons.local_hospital;
      case 'Grocery':
        return Icons.shopping_cart;
      case 'Shifting Furniture':
        return Icons.chair;
      case 'Route':
        return Icons.directions;
      case 'Pet Care':
        return Icons.pets;
      case 'Education':
        return Icons.school;
      case 'Repair':
        return Icons.build;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search help history...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF71BB7B),
                  size: 20,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 18,
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Row
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Time', _selectedTimeFilter, _timeFilters, (
                    value,
                  ) {
                    setState(() {
                      _selectedTimeFilter = value;
                    });
                  }),
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    'Status',
                    _selectedStatusFilter,
                    _statusFilters,
                    (value) {
                      setState(() {
                        _selectedStatusFilter = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder:
          (context) =>
              options
                  .map(
                    (option) =>
                        PopupMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              selectedValue != options.first
                  ? const Color(0xFF71BB7B)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                color:
                    selectedValue != options.first
                        ? Colors.white
                        : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color:
                  selectedValue != options.first
                      ? Colors.white
                      : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTrustInfo(HelpHistory help) {
    // Get user ID for the person we interacted with
    final String userId =
        help.isReceived ? (help.helperName ?? 'helper') : help.requesterName;

    // Get trust metrics from feedback service
    final double avgRating = FeedbackService.getAverageRating(userId);
    final int feedbackCount = FeedbackService.getFeedbackCount(userId);
    final double trustScore = FeedbackService.getTrustScore(userId);

    if (feedbackCount == 0) {
      return Row(
        children: [
          Icon(Icons.fiber_new, size: 12, color: Colors.orange[600]),
          const SizedBox(width: 4),
          Text(
            'New User',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Rating stars
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < avgRating ? Icons.star : Icons.star_border,
              size: 10,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(width: 4),
        Text(
          avgRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($feedbackCount)',
          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
        ),
        const SizedBox(width: 8),
        // Trust badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _getTrustColor(trustScore),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, size: 8, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                '${trustScore.toInt()}%',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getTrustColor(double trustScore) {
    if (trustScore >= 90) return Colors.green;
    if (trustScore >= 75) return const Color(0xFF71BB7B);
    if (trustScore >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHistoryCard(HelpHistory help) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showHistoryDetails(help),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      help.isReceived
                          ? (help.helperImage ?? help.requesterImage)
                          : help.requesterImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          help.isReceived
                              ? (help.helperName ?? 'Helper')
                              : help.requesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              help.isReceived
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 14,
                              color:
                                  help.isReceived ? Colors.blue : Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              help.isReceived
                                  ? 'Help Received'
                                  : 'Help Provided',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    help.isReceived
                                        ? Colors.blue
                                        : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // User Trust Score and Rating
                        _buildUserTrustInfo(help),
                      ],
                    ),
                  ),

                  // Status and Date Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(help.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          help.status,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(help.dateCompleted),
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Help Type and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getHelpTypeIcon(help.helpType),
                          size: 14,
                          color: const Color(0xFF71BB7B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          help.helpType,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF71BB7B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                help.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                help.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom Row with stats
              Row(
                children: [
                  if (help.rating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.amber[700]),
                          const SizedBox(width: 4),
                          Text(
                            '${help.rating}/5',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (help.helpValuePoints > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${help.helpValuePoints} pts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          help.duration,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  _buildActionButton(
                    'Details',
                    Icons.info_outline,
                    Colors.grey[700]!,
                    () => _showHistoryDetails(help),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetails(HelpHistory help) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        help.isReceived
                            ? (help.helperImage ?? help.requesterImage)
                            : help.requesterImage,
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
                            help.isReceived
                                ? (help.helperName ?? 'Helper')
                                : help.requesterName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                help.isReceived
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 16,
                                color:
                                    help.isReceived
                                        ? Colors.blue
                                        : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                help.isReceived
                                    ? 'Help Received'
                                    : 'Help Provided',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      help.isReceived
                                          ? Colors.blue
                                          : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(help.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        help.status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Help Type
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF71BB7B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getHelpTypeIcon(help.helpType),
                        size: 18,
                        color: const Color(0xFF71BB7B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        help.helpType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71BB7B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  help.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  help.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Location: ${help.location}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Duration: ${help.duration}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Date: ${_formatFullDate(help.dateCompleted)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Rating and Points (if completed)
                if (help.status == 'Completed') ...[
                  Row(
                    children: [
                      if (help.rating != null) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 32,
                                  color: Colors.amber[700],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${help.rating}/5',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Rating',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      if (help.helpValuePoints > 0) ...[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  size: 32,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '+${help.helpValuePoints}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Points',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Feedback (if available)
                if (help.feedback != null) ...[
                  Text(
                    'Feedback:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF71BB7B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF71BB7B).withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      help.feedback!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons based on status
                if (help.status == 'In Progress') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Update status functionality
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.update),
                          label: const Text('Update Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Message functionality
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.message),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF71BB7B),
                            side: const BorderSide(color: Color(0xFF71BB7B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (help.status == 'Completed') ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to feedback page with pre-filled data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ReportFeedbackPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Leave Feedback'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF71BB7B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to report page with pre-filled data
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const ReportFeedbackPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.report_outlined),
                          label: const Text('Report Issue'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildStatsOverview() {
    final completedProvided =
        _helpProvided.where((h) => h.status == 'Completed').length;
    final completedReceived =
        _helpReceived.where((h) => h.status == 'Completed').length;
    final totalPoints = _helpProvided
        .where((h) => h.status == 'Completed')
        .fold(0, (sum, h) => sum + h.helpValuePoints);
    final avgRating =
        _helpProvided
            .where((h) => h.rating != null)
            .fold(0.0, (sum, h) => sum + h.rating!) /
        _helpProvided.where((h) => h.rating != null).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF71BB7B), const Color(0xFF5EA968)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF71BB7B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'My Help Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Provided',
                  completedProvided.toString(),
                  Icons.volunteer_activism,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Received',
                  completedReceived.toString(),
                  Icons.help_outline,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Points',
                  totalPoints.toString(),
                  Icons.emoji_events,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Rating',
                  avgRating.isNaN ? '0.0' : avgRating.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
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
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Help History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                  const Icon(Icons.volunteer_activism),
                  const SizedBox(width: 8),
                  Text(
                    'Provided (${_getFilteredHistory(_helpProvided).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.help_outline),
                  const SizedBox(width: 8),
                  Text(
                    'Received (${_getFilteredHistory(_helpReceived).length})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScrollableHistoryView(_helpProvided, true),
          _buildScrollableHistoryView(_helpReceived, false),
        ],
      ),
    );
  }

  Widget _buildScrollableHistoryView(
    List<HelpHistory> history,
    bool isProvided,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Statistics Overview - will collapse when scrolling up
        SliverToBoxAdapter(child: _buildStatsOverview()),

        // Sticky Search/Filter Section
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyHeaderDelegate(
            minHeight: 120,
            maxHeight: 120,
            child: _buildFilterSection(),
          ),
        ),

        // History List
        _buildSliverHistoryList(history, isProvided),
      ],
    );
  }

  Widget _buildSliverHistoryList(List<HelpHistory> history, bool isProvided) {
    final filteredHistory = _getFilteredHistory(history);

    if (filteredHistory.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isProvided ? Icons.volunteer_activism : Icons.help_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                isProvided ? 'No help provided yet' : 'No help received yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isProvided
                    ? 'Start helping your neighbors to build your contribution history'
                    : 'Request help from your community when you need it',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildHistoryCard(filteredHistory[index]);
      }, childCount: filteredHistory.length),
    );
  }
}

// Custom delegate for sticky header behavior
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

class HelpHistory {
  final String id;
  final String title;
  final String description;
  final String helpType;
  final String status;
  final String requesterName;
  final String requesterImage;
  final String? helperName;
  final String? helperImage;
  final String location;
  final DateTime dateCompleted;
  final String duration;
  final int? rating;
  final String? feedback;
  final int helpValuePoints;
  final bool isReceived;

  HelpHistory({
    required this.id,
    required this.title,
    required this.description,
    required this.helpType,
    required this.status,
    required this.requesterName,
    required this.requesterImage,
    this.helperName,
    this.helperImage,
    required this.location,
    required this.dateCompleted,
    required this.duration,
    this.rating,
    this.feedback,
    required this.helpValuePoints,
    this.isReceived = false,
  });
}
