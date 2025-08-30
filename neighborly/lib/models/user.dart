import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class User {
  final String email;
  final String username;
  final String? contact;
  final String? address;
  final String? bloodGroup;
  final List<String>
  preferredCommunity; // Changed to List<String> for multiple communities
  final String? profilePicture;
  final String firebaseUid;
  final bool isAdmin;
  final bool blocked;

  User({
    required this.email,
    required this.username,
    required this.firebaseUid,
    required this.isAdmin,
    required this.blocked,
    this.contact,
    this.address,
    this.bloodGroup,
    this.preferredCommunity = const [], // Default to empty list
    this.profilePicture,
  });

  // Create User from Firestore data
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    // Handle both old format (String) and new format (List<String>) for preferredCommunity
    List<String> communities = [];
    final communityData = data['preferredCommunity'];

    if (communityData != null) {
      if (communityData is List) {
        // New format: already a list
        communities = List<String>.from(communityData);
      } else if (communityData is String && communityData.isNotEmpty) {
        // Old format: single string, convert to list
        communities = [communityData];
      }
    }

    return User(
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      firebaseUid: uid,
      isAdmin: data['isAdmin'] ?? false,
      blocked: data['blocked'] ?? false,
      contact: data['contact'],
      address: data['address'],
      bloodGroup: data['bloodGroup'],
      preferredCommunity: communities,
      profilePicture: data['profilepicurl'] ?? '',
    );
  }

  // Convert User to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'contact': contact,
      'address': address,
      'bloodGroup': bloodGroup,
      'preferredCommunity': preferredCommunity, // Now saves as List<String>
      'profilePicture': profilePicture,
      'firebaseUid': firebaseUid,
      'isAdmin': isAdmin,
      'blocked': blocked,
    };
  }
}
