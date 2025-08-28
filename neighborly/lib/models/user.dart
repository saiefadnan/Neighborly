class User {
  final String email;
  final String username;
  final String? contact;
  final String? address;
  final String? bloodGroup;
  final String? preferredCommunity;
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
    this.preferredCommunity,
    this.profilePicture,
  });

  // Create User from Firestore data
  factory User.fromFirestore(Map<String, dynamic> data, String uid) {
    return User(
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      firebaseUid: uid,
      isAdmin: data['isAdmin'] ?? false,
      blocked: data['blocked'] ?? false,
      contact: data['contact'],
      address: data['address'],
      bloodGroup: data['bloodGroup'],
      preferredCommunity: data['preferredCommunity'],
      profilePicture: data['profilePicture'],
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
      'preferredCommunity': preferredCommunity,
      'profilePicture': profilePicture,
      'firebaseUid': firebaseUid,
      'isAdmin': isAdmin,
      'blocked': blocked,
    };
  }
}
