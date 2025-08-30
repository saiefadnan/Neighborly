import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/functions/signin_token.dart';
import 'package:neighborly/functions/signup_token.dart';
import 'package:neighborly/functions/token_verify.dart';
import 'package:neighborly/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUser extends AsyncNotifier<User?> {
  @override
  User? build() {
    // Check if user is already logged in when the provider initializes
    _checkExistingUser();
    return null;
  }

  // Get current user (simple access from anywhere)
  User? get user => state.value;

  // Method to ensure user data is loaded
  Future<void> ensureUserDataLoaded() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null && state.value == null) {
      await _fetchUserData();
    }
  }

  // Check if there's an existing logged-in user and fetch their data
  Future<void> _checkExistingUser() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && state.value == null) {
      print('🔄 Found existing logged-in user, fetching data...');
      await _fetchUserData();
    }
  }

  Future<void> userAuthentication({
    String? name,
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncLoading();
      String? idToken;
      if (name != null && name.isNotEmpty) {
        idToken = await signUpAndGetIdToken(name, email, password);
      } else {
        idToken = await signInAndGetIdToken(email, password);
      }
      if (idToken == null) {
        throw Exception('Authentication failed!');
      }
      bool verified = await verifyToken(idToken).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('backend failed. Alternative way is initiating...');
          return false;
        },
      );

      if (!verified) {
        print('Demo fallback: allowing login despite backend failure.');
        verified = true;
      }

      if (verified) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('rememberMe', rememberMe);

        // Fetch user data from Firestore after successful login
        await _fetchUserData();

        // State is already updated in _fetchUserData via _notifyUserDataChanged
      } else {
        throw Exception('Invalid user credentials!');
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void initState() {
    state = const AsyncData(null);
  }

  void stateOnRemember() {
    // Fetch user data when remembering state
    _checkExistingUser();
  }

  // Simple method to fetch user data from Firestore
  Future<void> _fetchUserData() async {
    try {
      print('🔍 Starting user data fetch...');
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      print('🔍 Firebase user: ${firebaseUser?.email}');

      if (firebaseUser != null) {
        print('🔍 Fetching from Firestore with email: ${firebaseUser.email}');
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.email)
                .get();

        print('🔍 Document exists: ${doc.exists}');
        if (doc.exists) {
          print('🔍 Document data: ${doc.data()}');
          final userData = User.fromFirestore(doc.data()!, firebaseUser.uid);
          print('✅ User data loaded: ${userData.username}');
          state = AsyncData(userData); // Update state with user data
        } else {
          print(
            '⚠️ No user document found in Firestore for email: ${firebaseUser.email}',
          );
          // Let's also try to check if document exists with a different ID
          final querySnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: firebaseUser.email)
                  .get();
          print(
            '🔍 Query results: ${querySnapshot.docs.length} documents found',
          );
          if (querySnapshot.docs.isNotEmpty) {
            print('🔍 Found user document with different ID');
            final userData = User.fromFirestore(
              querySnapshot.docs.first.data(),
              firebaseUser.uid,
            );
            print('✅ User data loaded from query: ${userData.username}');
            state = AsyncData(userData); // Update state with user data
          }
        }
      } else {
        print('❌ No Firebase user found');
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  // Clear user data on logout
  void logout() {
    state = const AsyncData(null);
  }

  // Public method to manually fetch user data (for testing)
  Future<void> fetchUserData() async {
    await _fetchUserData();
  }
}
