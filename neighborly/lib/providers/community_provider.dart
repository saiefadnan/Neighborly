import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../services/community_service.dart';

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
  final bool isPending; // for join requests

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
    this.isPending = false,
  });

  factory CommunityData.fromJson(Map<String, dynamic> json) {
    return CommunityData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'],
      admins: List<String>.from(json['admins'] ?? []),
      members: List<String>.from(json['members'] ?? []),
      joinRequests: List<String>.from(json['joinRequests'] ?? []),
      memberCount: json['memberCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      recentActivity: json['recentActivity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'admins': admins,
      'members': members,
      'joinRequests': joinRequests,
      'memberCount': memberCount,
      'tags': tags,
      'recentActivity': recentActivity,
    };
  }

  CommunityData copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? imageUrl,
    List<String>? admins,
    List<String>? members,
    List<String>? joinRequests,
    int? memberCount,
    List<String>? tags,
    DateTime? joinDate,
    String? recentActivity,
    bool? isPending,
  }) {
    return CommunityData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      admins: admins ?? this.admins,
      members: members ?? this.members,
      joinRequests: joinRequests ?? this.joinRequests,
      memberCount: memberCount ?? this.memberCount,
      tags: tags ?? this.tags,
      joinDate: joinDate ?? this.joinDate,
      recentActivity: recentActivity ?? this.recentActivity,
      isPending: isPending ?? this.isPending,
    );
  }
}

class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  List<CommunityData> _allCommunities = [];
  List<CommunityData> _myCommunities = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CommunityData> get allCommunities => _allCommunities;
  List<CommunityData> get myCommunities => _myCommunities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get communities available to join (not in user's communities)
  List<CommunityData> get availableCommunities {
    final myCommunitiesIds = _myCommunities.map((c) => c.id).toSet();
    return _allCommunities
        .where((c) => !myCommunitiesIds.contains(c.id))
        .toList();
  }

  // Initialize - fetch all communities and user's communities
  Future<void> initializeCommunities() async {
    await Future.wait([fetchAllCommunities(), fetchUserCommunities()]);
  }

  // Fetch all communities from backend
  Future<void> fetchAllCommunities() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final communities = await _communityService.getAllCommunities();
      _allCommunities = communities;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching all communities: $e');
    }
  }

  // Fetch user's communities
  Future<void> fetchUserCommunities([String? userEmail]) async {
    try {
      String? userEmailToUse = userEmail;

      // If no userEmail provided, try to get it from Firebase Auth
      if (userEmailToUse == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        userEmailToUse = user.email ?? '';
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final communities = await _communityService.getUserCommunities(
        userEmailToUse,
      );
      _myCommunities = communities;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error fetching user communities: $e');
    }
  }

  // Join a community
  Future<bool> joinCommunity(
    String communityId, {
    String? userId,
    String? userEmail,
  }) async {
    try {
      String? userIdToUse = userId;
      String? userEmailToUse = userEmail;

      // If no user info provided, try to get it from Firebase Auth
      if (userIdToUse == null || userEmailToUse == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _error = 'User not logged in';
          notifyListeners();
          return false;
        }
        userIdToUse = user.uid;
        userEmailToUse = user.email ?? '';
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _communityService.joinCommunity(
        userIdToUse,
        communityId,
        userEmailToUse,
        autoJoin:
            true, // Auto-join for now, can be changed to false for admin approval
      );

      if (result['success'] == true) {
        // Find the community in all communities and move it to my communities
        final communityIndex = _allCommunities.indexWhere(
          (c) => c.id == communityId,
        );
        if (communityIndex != -1) {
          final community = _allCommunities[communityIndex].copyWith(
            joinDate: DateTime.now(),
            memberCount: _allCommunities[communityIndex].memberCount + 1,
          );
          _myCommunities.add(community);

          // Update the community in all communities list with new member count
          _allCommunities[communityIndex] = community;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to join community';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error joining community: $e');
      return false;
    }
  }

  // Leave a community
  Future<bool> leaveCommunity(
    String communityId, {
    String? userId,
    String? userEmail,
  }) async {
    try {
      String? userIdToUse = userId;
      String? userEmailToUse = userEmail;

      // If no user info provided, try to get it from Firebase Auth
      if (userIdToUse == null || userEmailToUse == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _error = 'User not logged in';
          notifyListeners();
          return false;
        }
        userIdToUse = user.uid;
        userEmailToUse = user.email ?? '';
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _communityService.leaveCommunity(
        userIdToUse,
        communityId,
        userEmailToUse,
      );

      if (result['success'] == true) {
        // Remove community from my communities
        final communityIndex = _myCommunities.indexWhere(
          (c) => c.id == communityId,
        );
        if (communityIndex != -1) {
          final community = _myCommunities[communityIndex];
          _myCommunities.removeAt(communityIndex);

          // Update the community in all communities list with decreased member count
          final allCommunitiesIndex = _allCommunities.indexWhere(
            (c) => c.id == communityId,
          );
          if (allCommunitiesIndex != -1) {
            _allCommunities[allCommunitiesIndex] = community.copyWith(
              memberCount: math.max(community.memberCount - 1, 0),
              joinDate: null,
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to leave community';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error leaving community: $e');
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await initializeCommunities();
  }
}
