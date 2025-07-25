import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpListPage extends StatefulWidget {
  const HelpListPage({super.key});

  @override
  State<HelpListPage> createState() => _HelpListPageState();
}

class _HelpListPageState extends State<HelpListPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedHelpType = 'All';
  String _selectedUrgency = 'All';
  bool _nearbyOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _helpTypes = [
    'All',
    'Medical',
    'Fire',
    'Shifting House',
    'Grocery',
    'Traffic Update',
    'Route',
    'Shifting Furniture',
  ];
  final List<String> _urgencyLevels = ['All', 'Emergency', 'Urgent', 'General'];

  final List<HelpRequest> _communityHelps = [
    HelpRequest(
      id: '1',
      title: 'Emergency Medical Help',
      description:
          'My elderly neighbor has fallen and needs immediate medical attention. Please help!',
      helpType: 'Medical',
      urgency: 'Emergency',
      location: 'Dhanmondi 15, Dhaka',
      distance: '0.2 km',
      timePosted: '5 min ago',
      requesterName: 'Sarah Ahmed',
      requesterImage: 'assets/images/Image1.jpg',
      contactNumber: '+880171234567',
      isResponded: false,
      responderCount: 0,
    ),
    HelpRequest(
      id: '2',
      title: 'House Fire Alert',
      description:
          'There\'s a fire in building 23. Fire service has been called but need community help for evacuation.',
      helpType: 'Fire',
      urgency: 'Emergency',
      location: 'Gulshan 2, Dhaka',
      distance: '1.5 km',
      timePosted: '8 min ago',
      requesterName: 'Karim Hassan',
      requesterImage: 'assets/images/Image2.jpg',
      contactNumber: '+880171234568',
      isResponded: true,
      responderCount: 3,
    ),
    HelpRequest(
      id: '3',
      title: 'Grocery Shopping Help',
      description:
          'I\'m sick and unable to go out. Need someone to buy groceries for my family.',
      helpType: 'Grocery',
      urgency: 'Urgent',
      location: 'Dhanmondi 27, Dhaka',
      distance: '0.8 km',
      timePosted: '25 min ago',
      requesterName: 'Fatima Khan',
      requesterImage: 'assets/images/Image3.jpg',
      contactNumber: '+880171234569',
      isResponded: false,
      responderCount: 1,
    ),
    HelpRequest(
      id: '4',
      title: 'Furniture Moving',
      description:
          'Need help moving furniture to the 4th floor. Heavy items involved.',
      helpType: 'Shifting Furniture',
      urgency: 'General',
      location: 'Bashundhara R/A, Dhaka',
      distance: '3.2 km',
      timePosted: '1 hour ago',
      requesterName: 'Abdul Rahman',
      requesterImage: 'assets/images/Image1.jpg',
      contactNumber: '+880171234570',
      isResponded: false,
      responderCount: 2,
    ),
    HelpRequest(
      id: '5',
      title: 'Traffic Jam Update',
      description:
          'Major accident on Mirpur road. Traffic completely blocked. Find alternative routes.',
      helpType: 'Traffic Update',
      urgency: 'Urgent',
      location: 'Mirpur 10, Dhaka',
      distance: '5.1 km',
      timePosted: '45 min ago',
      requesterName: 'Nasir Ahmed',
      requesterImage: 'assets/images/Image2.jpg',
      contactNumber: '+880171234571',
      isResponded: true,
      responderCount: 5,
    ),
  ];

  final List<HelpRequest> _myHelps = [
    HelpRequest(
      id: '6',
      title: 'Looking for Tutoring Help',
      description:
          'Need a math tutor for my 10th grade son. Preferably someone nearby.',
      helpType: 'General',
      urgency: 'General',
      location: 'Dhanmondi 15, Dhaka',
      distance: '0 km',
      timePosted: '2 hours ago',
      requesterName: 'Ali Rahman',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: '+880171234572',
      isResponded: false,
      responderCount: 0,
    ),
    HelpRequest(
      id: '7',
      title: 'Pet Care While Away',
      description:
          'Going out of town for 3 days. Need someone to take care of my cat.',
      helpType: 'General',
      urgency: 'Urgent',
      location: 'Dhanmondi 15, Dhaka',
      distance: '0 km',
      timePosted: '1 day ago',
      requesterName: 'Ali Rahman',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: '+880171234572',
      isResponded: true,
      responderCount: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sortHelpsByUrgency();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sortHelpsByUrgency() {
    final urgencyPriority = {'Emergency': 0, 'Urgent': 1, 'General': 2};

    _communityHelps.sort((a, b) {
      int priorityA = urgencyPriority[a.urgency] ?? 3;
      int priorityB = urgencyPriority[b.urgency] ?? 3;
      return priorityA.compareTo(priorityB);
    });

    _myHelps.sort((a, b) {
      int priorityA = urgencyPriority[a.urgency] ?? 3;
      int priorityB = urgencyPriority[b.urgency] ?? 3;
      return priorityA.compareTo(priorityB);
    });
  }

  List<HelpRequest> _getFilteredHelps(List<HelpRequest> helps) {
    return helps.where((help) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          help.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          help.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          help.location.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesHelpType =
          _selectedHelpType == 'All' || help.helpType == _selectedHelpType;
      bool matchesUrgency =
          _selectedUrgency == 'All' || help.urgency == _selectedUrgency;
      bool matchesDistance =
          !_nearbyOnly || double.parse(help.distance.split(' ')[0]) <= 2.0;

      return matchesSearch &&
          matchesHelpType &&
          matchesUrgency &&
          matchesDistance;
    }).toList();
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'Emergency':
        return Colors.red;
      case 'Urgent':
        return Colors.orange;
      case 'General':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getHelpTypeIcon(String helpType) {
    switch (helpType) {
      case 'Medical':
        return Icons.local_hospital;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Grocery':
        return Icons.shopping_cart;
      case 'Shifting House':
        return Icons.home;
      case 'Shifting Furniture':
        return Icons.chair;
      case 'Traffic Update':
        return Icons.traffic;
      case 'Route':
        return Icons.directions;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          Container(
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
                hintText: 'Search help requests...',
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
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Help Type', _selectedHelpType, _helpTypes, (
                  value,
                ) {
                  setState(() {
                    _selectedHelpType = value;
                  });
                }),
                const SizedBox(width: 12),
                _buildFilterChip('Urgency', _selectedUrgency, _urgencyLevels, (
                  value,
                ) {
                  setState(() {
                    _selectedUrgency = value;
                  });
                }),
                const SizedBox(width: 12),
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color:
                            _nearbyOnly
                                ? Colors.white
                                : const Color(0xFF71BB7B),
                      ),
                      const SizedBox(width: 4),
                      const Text('Nearby (2km)'),
                    ],
                  ),
                  selected: _nearbyOnly,
                  onSelected: (value) {
                    setState(() {
                      _nearbyOnly = value;
                    });
                  },
                  selectedColor: const Color(0xFF71BB7B),
                  checkmarkColor: Colors.white,
                ),
              ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selectedValue != options.first
                  ? const Color(0xFF71BB7B)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
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
              size: 16,
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

  Widget _buildHelpCard(HelpRequest help, bool isMyHelp) {
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
        onTap: () => _showHelpDetails(help),
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
                      help.requesterImage,
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
                          help.requesterName,
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
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${help.location} • ${help.distance}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Time and Urgency Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        help.timePosted,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getUrgencyColor(help.urgency),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          help.urgency,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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

              // Response Status and Actions
              Row(
                children: [
                  if (help.responderCount > 0) ...[
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
                            Icons.people,
                            size: 12,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${help.responderCount} responding',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  if (help.isResponded) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Responded',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ] else ...[
                    const Spacer(),
                    if (!isMyHelp)
                      _buildActionButton(
                        'Respond',
                        Icons.reply,
                        const Color(0xFF71BB7B),
                        () => _respondToHelp(help),
                      ),
                  ],

                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Details',
                    Icons.info_outline,
                    Colors.blue,
                    () => _showHelpDetails(help),
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

  Widget _buildHelpList(List<HelpRequest> helps, bool isMyHelp) {
    final filteredHelps = _getFilteredHelps(helps);

    if (filteredHelps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMyHelp ? Icons.help_outline : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isMyHelp
                  ? 'No help requests posted yet'
                  : _searchQuery.isEmpty
                  ? 'No help requests available'
                  : 'No help requests found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isMyHelp) ...[
              const SizedBox(height: 8),
              Text(
                'Your posted help requests will appear here',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredHelps.length,
      itemBuilder: (context, index) {
        return _buildHelpCard(filteredHelps[index], isMyHelp);
      },
    );
  }

  void _respondToHelp(HelpRequest help) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final TextEditingController responseController =
            TextEditingController();
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
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
              Text(
                'Respond to ${help.requesterName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Help: ${help.title}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: responseController,
                  decoration: const InputDecoration(
                    hintText: 'Type your response...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          help.isResponded = true;
                          help.responderCount++;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Response sent to ${help.requesterName}',
                            ),
                            backgroundColor: const Color(0xFF71BB7B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF71BB7B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDetails(HelpRequest help) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                        help.requesterImage,
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
                            help.requesterName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            help.location,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
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
                        color: _getUrgencyColor(help.urgency),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        help.urgency,
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
                            Icons.access_time,
                            size: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Posted: ${help.timePosted}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                              '${help.location} (${help.distance} away)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            help.contactNumber,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Call functionality
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF71BB7B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.call,
                                size: 16,
                                color: Color(0xFF71BB7B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Response status
                if (help.responderCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          '${help.responderCount} people are responding to this request',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Action buttons
                if (!help.isResponded &&
                    help.requesterName != 'Ali Rahman') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _respondToHelp(help);
                      },
                      icon: const Icon(Icons.reply),
                      label: const Text('Respond to Help Request'),
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
                ] else if (help.isResponded) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'You have responded to this request',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
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
        automaticallyImplyLeading: false, // Remove back button
        title: const Row(
          children: [
            Icon(Icons.list_alt, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Help Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
                  const Icon(Icons.public),
                  const SizedBox(width: 8),
                  Text(
                    'Community (${_getFilteredHelps(_communityHelps).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Text('My Requests (${_myHelps.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHelpList(_communityHelps, false),
                _buildHelpList(_myHelps, true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpRequest {
  final String id;
  final String title;
  final String description;
  final String helpType;
  final String urgency;
  final String location;
  final String distance;
  final String timePosted;
  final String requesterName;
  final String requesterImage;
  final String contactNumber;
  bool isResponded;
  int responderCount;

  HelpRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.helpType,
    required this.urgency,
    required this.location,
    required this.distance,
    required this.timePosted,
    required this.requesterName,
    required this.requesterImage,
    required this.contactNumber,
    required this.isResponded,
    required this.responderCount,
  });
}
