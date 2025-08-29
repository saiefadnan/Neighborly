import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/help_list_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class HelpRequestData {
  final String id;
  final String userId;
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
  final LatLng? coordinates;
  bool isResponded;
  int responderCount;

  HelpRequestData({
    required this.id,
    required this.userId,
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
    this.coordinates,
    this.isResponded = false,
    this.responderCount = 0,
  });

  // Convert from old HelpRequest format
  static HelpRequestData fromLegacyFormat(Map<String, dynamic> helpData) {
    // Helper function to capitalize urgency properly
    String capitalizeUrgency(String priority) {
      switch (priority.toLowerCase()) {
        case 'emergency':
          return 'Emergency';
        case 'urgent':
          return 'Urgent';
        case 'general':
          return 'General';
        default:
          return 'General';
      }
    }

    return HelpRequestData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: helpData['userId'] ?? '',
      title: helpData['title'] ?? 'Help Request',
      description: helpData['description'] ?? '',
      helpType: helpData['title'] ?? 'General',
      urgency: capitalizeUrgency(helpData['priority'] ?? 'General'),
      location: helpData['address'] ?? '',
      distance: '0 km', // Default distance for new requests
      timePosted: 'Just now',
      requesterName: helpData['username'] ?? 'Anonymous',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: helpData['phone'] ?? '',
      coordinates: helpData['coordinates'] as LatLng?,
      isResponded: false,
      responderCount: 0,
    );
  }

  // Convert to map format for backwards compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'helpType': helpType,
      'priority': urgency.toLowerCase(),
      'address': location,
      'username': requesterName,
      'phone': contactNumber,
      'coordinates': coordinates,
      'time': timePosted,
    };
  }
}

class HelpRequestProvider with ChangeNotifier {
  final List<HelpRequestData> _helpRequests = [];
  bool _isInitialized = false;
  bool _loadedFromBackend = false;
  String? _currentUserId;

  List<HelpRequestData> get helpRequests => List.unmodifiable(_helpRequests);

  // Computed lists using userId when available, fallback to legacy name logic
  List<HelpRequestData> get communityHelps {
    if (_currentUserId != null) {
      return _helpRequests.where((h) => h.userId != _currentUserId).toList();
    }
    // Fallback legacy (name based)
    return _helpRequests
        .where(
          (h) => h.requesterName != 'Ali Rahman' && h.requesterName != 'Ali',
        )
        
        .toList();
  }

  List<HelpRequestData> get myHelps {
    if (_currentUserId != null) {
      return _helpRequests.where((h) => h.userId == _currentUserId).toList();
    }

    return [];
  }

  void addHelpRequest(HelpRequestData helpRequest) {
    _helpRequests.insert(0, helpRequest); // Add to beginning for newest first
    notifyListeners();
  }

  void addHelpRequestFromMap(Map<String, dynamic> helpData) {
    final helpRequest = HelpRequestData.fromLegacyFormat(helpData);
    addHelpRequest(helpRequest);
  }

  void updateHelpRequest(String id, {bool? isResponded, int? responderCount}) {
    final index = _helpRequests.indexWhere((help) => help.id == id);
    if (index != -1) {
      if (isResponded != null) {
        _helpRequests[index].isResponded = isResponded;
      }
      if (responderCount != null) {
        _helpRequests[index].responderCount = responderCount;
      }
      notifyListeners();
    }
  }

  Future<void> fetchHelpRequestsFromBackend({bool force = false}) async {
    if (_loadedFromBackend && !force) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      _currentUserId = user?.uid;
      final fetched = await HelpListService.fetchAllHelpRequests();
      _helpRequests
        ..clear()
        ..addAll(fetched);
      _loadedFromBackend = true;
      notifyListeners();
    } catch (e) {
      // Keep sample data if already there
      debugPrint('Failed to fetch help requests: $e');
    }
  }

  Future<void> fetchMyHelpRequests({bool force = false}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;

      // Get Firebase ID token
      final token = await user.getIdToken();

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/map/help-requests?userId=${user.uid}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> helpRequestsJson = data['data'] ?? [];

          // Clear existing requests and add fetched ones
          _helpRequests.removeWhere((h) => h.userId == _currentUserId);

          for (final helpJson in helpRequestsJson) {
            final helpRequest = _convertBackendDataToHelpRequest(helpJson);
            _helpRequests.add(helpRequest);
          }

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch my help requests: $e');
    }
  }

  // Helper method to convert backend data to HelpRequestData
  HelpRequestData _convertBackendDataToHelpRequest(Map<String, dynamic> data) {
    String capitalizeUrgency(String priority) {
      switch (priority.toLowerCase()) {
        case 'emergency':
          return 'Emergency';
        case 'urgent':
        case 'high':
          return 'Urgent';
        case 'general':
        case 'medium':
        case 'low':
          return 'General';
        default:
          return 'General';
      }
    }

    // Calculate time ago
    String getTimeAgo(String createdAt) {
      try {
        final createdTime = DateTime.parse(createdAt);
        final now = DateTime.now();
        final difference = now.difference(createdTime);

        if (difference.inMinutes < 1) {
          return 'Just now';
        } else if (difference.inMinutes < 60) {
          return '${difference.inMinutes} min ago';
        } else if (difference.inHours < 24) {
          return '${difference.inHours} hours ago';
        } else {
          return '${difference.inDays} days ago';
        }
      } catch (e) {
        return 'Recently';
      }
    }

    return HelpRequestData(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'Help Request',
      description: data['description'] ?? '',
      helpType: data['type'] ?? 'General',
      urgency: capitalizeUrgency(data['priority'] ?? 'General'),
      location: data['address'] ?? '',
      distance: '0 km', // Default for user's own requests
      timePosted: getTimeAgo(data['createdAt'] ?? ''),
      requesterName: data['username'] ?? 'Anonymous',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: data['phone'] ?? '',
      coordinates:
          data['location'] != null
              ? LatLng(
                data['location']['latitude']?.toDouble() ?? 0.0,
                data['location']['longitude']?.toDouble() ?? 0.0,
              )
              : null,
      isResponded: false,
      responderCount: data['responses']?.length ?? 0,
    );
  }

  void removeHelpRequest(String id) {
    _helpRequests.removeWhere((help) => help.id == id);
    notifyListeners();
  }

  HelpRequestData? getHelpRequestById(String id) {
    try {
      return _helpRequests.firstWhere((help) => help.id == id);
    } catch (e) {
      return null;
    }
  }

  List<HelpRequestData> getFilteredHelps({
    String? helpType,
    String? urgency,
    String? searchQuery,
    bool nearbyOnly = false,
    bool isMyHelp = false,
  }) {
    List<HelpRequestData> helps = isMyHelp ? myHelps : communityHelps;

    return helps.where((help) {
      bool matchesSearch =
          searchQuery == null ||
          searchQuery.isEmpty ||
          help.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          help.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          help.location.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesHelpType =
          helpType == null || helpType == 'All' || help.helpType == helpType;
      bool matchesUrgency =
          urgency == null || urgency == 'All' || help.urgency == urgency;
      bool matchesDistance =
          !nearbyOnly ||
          double.tryParse(help.distance.split(' ')[0]) != null &&
              double.parse(help.distance.split(' ')[0]) <= 2.0;

      return matchesSearch &&
          matchesHelpType &&
          matchesUrgency &&
          matchesDistance;
    }).toList();
  }

  void sortHelpsByUrgency() {
    final urgencyPriority = {'Emergency': 0, 'Urgent': 1, 'General': 2};

    _helpRequests.sort((a, b) {
      int priorityA = urgencyPriority[a.urgency] ?? 3;
      int priorityB = urgencyPriority[b.urgency] ?? 3;
      return priorityA.compareTo(priorityB);
    });
    notifyListeners();
  }

  // Initialize with sample data for demo purposes
  void initializeSampleData() {
    if (_isInitialized) return;
    _isInitialized = true;

    final sampleHelps = [
      HelpRequestData(
        id: 'sample_1',
        userId: 'user_sarah',
        title: 'Need help with groceries',
        description:
            'I\'m recovering from surgery and need someone to help me with grocery shopping. Can pay for gas and groceries.',
        helpType: 'Grocery',
        urgency: 'General',
        location: 'Maple Street, Downtown',
        distance: '0.8 km',
        timePosted: '2 hours ago',
        requesterName: 'Sarah Johnson',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 123-4567',
        coordinates: const LatLng(23.7510, 90.3890),
        responderCount: 2,
      ),
      HelpRequestData(
        id: 'sample_2',
        userId: 'user_mike',
        title: 'Emergency pet transport',
        description:
            'My cat is injured and I don\'t have a car to get to the emergency vet clinic. Please help!',
        helpType: 'Medical',
        urgency: 'Emergency',
        location: 'Oak Avenue, Midtown',
        distance: '1.2 km',
        timePosted: '30 minutes ago',
        requesterName: 'Mike Chen',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 987-6543',
        coordinates: const LatLng(23.7540, 90.3920),
        responderCount: 0,
      ),
      HelpRequestData(
        id: 'sample_3',
        userId: 'user_jessica',
        title: 'Babysitting for job interview',
        description:
            'I have an important job interview tomorrow and need someone to watch my 5-year-old for 2 hours.',
        helpType: 'Medical',
        urgency: 'Urgent',
        location: 'Pine Street, Uptown',
        distance: '2.1 km',
        timePosted: '1 hour ago',
        requesterName: 'Jessica Martinez',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 456-7890',
        coordinates: const LatLng(23.7480, 90.3850),
        responderCount: 1,
      ),
      HelpRequestData(
        id: 'sample_4',
        userId: 'user_david',
        title: 'Moving boxes to apartment',
        description:
            'Need 2-3 people to help move some boxes and furniture to my new apartment on the 3rd floor.',
        helpType: 'Shifting House',
        urgency: 'General',
        location: 'Elm Street, Riverside',
        distance: '1.7 km',
        timePosted: '4 hours ago',
        requesterName: 'David Wilson',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 321-0987',
        coordinates: const LatLng(23.7560, 90.3940),
        responderCount: 3,
      ),
      HelpRequestData(
        id: 'sample_5',
        userId: 'user_emily',
        title: 'Senior assistance with technology',
        description:
            'My elderly neighbor needs help setting up her new smartphone and learning basic functions.',
        helpType: 'Route',
        urgency: 'General',
        location: 'Cedar Lane, Westside',
        distance: '0.5 km',
        timePosted: '3 hours ago',
        requesterName: 'Emily Rodriguez',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 654-3210',
        coordinates: const LatLng(23.7450, 90.3870),
        responderCount: 1,
      ),
      HelpRequestData(
        id: 'sample_6',
        userId: 'user_robert',
        title: 'Need ride to hospital',
        description:
            'I have a medical appointment and my car broke down. Need transportation to City Hospital.',
        helpType: 'Medical',
        urgency: 'Urgent',
        location: 'Main Street, Central',
        distance: '1.0 km',
        timePosted: '45 minutes ago',
        requesterName: 'Robert Taylor',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 789-0123',
        coordinates: const LatLng(23.7520, 90.3900),
        responderCount: 0,
      ),
      HelpRequestData(
        id: 'sample_7',
        userId: 'user_lisa',
        title: 'Dog walking while away',
        description:
            'Going out of town for the weekend and need someone to walk my dog twice a day.',
        helpType: 'Route',
        urgency: 'General',
        location: 'Birch Road, Northside',
        distance: '2.3 km',
        timePosted: '6 hours ago',
        requesterName: 'Lisa Thompson',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 012-3456',
        coordinates: const LatLng(23.7580, 90.3960),
        responderCount: 2,
      ),
      HelpRequestData(
        id: 'sample_8',
        userId: 'user_amanda',
        title: 'Furniture arrangement help',
        description:
            'Recently moved and need help arranging heavy furniture in my new living room.',
        helpType: 'Shifting Furniture',
        urgency: 'General',
        location: 'Willow Street, Eastside',
        distance: '1.5 km',
        timePosted: '5 hours ago',
        requesterName: 'Amanda Davis',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 567-8901',
        coordinates: const LatLng(23.7470, 90.3930),
        responderCount: 1,
      ),
      HelpRequestData(
        id: 'sample_9',
        userId: 'user_michael',
        title: 'House fire emergency!',
        description:
            'Small kitchen fire contained but need help with smoke damage cleanup. Fire department already called.',
        helpType: 'Fire',
        urgency: 'Emergency',
        location: 'Cherry Lane, Eastside',
        distance: '0.9 km',
        timePosted: '20 minutes ago',
        requesterName: 'Michael Brown',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 111-2222',
        coordinates: const LatLng(23.7490, 90.3910),
        responderCount: 4,
      ),
      HelpRequestData(
        id: 'sample_10',
        userId: 'user_reporter',
        title: 'Traffic update - road blocked',
        description:
            'Major accident on Highway 15. Traffic backed up for miles. Find alternate routes.',
        helpType: 'Traffic Update',
        urgency: 'Urgent',
        location: 'Highway 15, North Junction',
        distance: '3.2 km',
        timePosted: '15 minutes ago',
        requesterName: 'Traffic Reporter',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+1 (555) 333-4444',
        coordinates: const LatLng(23.7600, 90.3980),
        responderCount: 12,
      ),
      HelpRequestData(
        id: 'my_sample_1',
        userId: 'current_user',
        title: 'Emergency - Need immediate help!',
        description:
            'Urgent situation requiring immediate assistance. Please respond quickly.',
        helpType: 'Medical',
        urgency: 'Emergency',
        location: 'My Location, Downtown',
        distance: '0.0 km',
        timePosted: '10 minutes ago',
        requesterName: 'Ali Rahman',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+880171234567',
        coordinates: const LatLng(23.7500, 90.3880),
        responderCount: 3,
      ),
      HelpRequestData(
        id: 'my_sample_2',
        userId: 'current_user',
        title: 'Urgent help needed with moving',
        description:
            'Need help moving furniture today. Time sensitive request.',
        helpType: 'Shifting Furniture',
        urgency: 'Urgent',
        location: 'My Apartment, Central',
        distance: '0.0 km',
        timePosted: '45 minutes ago',
        requesterName: 'Ali Rahman',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+880171234567',
        coordinates: const LatLng(23.7500, 90.3880),
        responderCount: 1,
      ),
      HelpRequestData(
        id: 'my_sample_3',
        userId: 'current_user',
        title: 'General help with groceries',
        description:
            'Looking for someone to help with weekly grocery shopping. Not urgent.',
        helpType: 'Grocery',
        urgency: 'General',
        location: 'Near My Home, Uptown',
        distance: '0.0 km',
        timePosted: '2 hours ago',
        requesterName: 'Ali Rahman',
        requesterImage: 'assets/images/dummy.png',
        contactNumber: '+880171234567',
        coordinates: const LatLng(23.7500, 90.3880),
        responderCount: 0,
      ),
    ];

    // Add all sample help requests
    for (final help in sampleHelps) {
      _helpRequests.add(help);
    }

    notifyListeners();
  }
}
