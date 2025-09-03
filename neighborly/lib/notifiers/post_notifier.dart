import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

final postsProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<List<Map<String, dynamic>>>>(
      (ref) => PostNotifier(ref),
    );

class PostNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;
  final GeoHasher geoHasher;

  PostNotifier(this.ref) : geoHasher = GeoHasher(), super(AsyncLoading()) {
    loadNearByPosts();
  }

  Future<void> loadPosts() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .get();
      final posts = querySnapshot.docs.map((doc) => {...doc.data()}).toList();
      state = AsyncData(posts);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String> _getCurrentLocation() async {
    try {
      bool servicesEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 15));

      String locationName = 'Unknown location';

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String area = '';
        String city = '';

        // Get the most specific area (neighborhood/district)
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          area = place.subLocality!;
        } else if (place.thoroughfare != null &&
            place.thoroughfare!.isNotEmpty) {
          area = place.thoroughfare!;
        } else if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty) {
          area = place.subAdministrativeArea!;
        }

        // Get the city
        if (place.locality != null && place.locality!.isNotEmpty) {
          city = place.locality!;
        } else if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          city = place.administrativeArea!;
        }

        // Create simple format: "Area, City"
        if (area.isNotEmpty && city.isNotEmpty) {
          locationName = '$area, $city';
        } else if (city.isNotEmpty) {
          locationName = city;
        } else if (area.isNotEmpty) {
          locationName = area;
        }
      }
      return locationName;
    } catch (e) {
      print('Error fetching location: $e');
      return '';
    }
  }

  // Load posts within specified radius from current location
  Future<void> loadNearByPosts({double radiusKm = 10.0}) async {
    try {
      String locationName = await _getCurrentLocation();

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('location.name', isEqualTo: locationName)
              .orderBy('timestamp', descending: true)
              .get();
      final posts = querySnapshot.docs.map((doc) => {...doc.data()}).toList();
      state = AsyncData(posts);
    } catch (e, st) {
      print('Error loading nearby posts: $e');
      state = AsyncError(e, st);
    }
  }

  void addPosts(Map<String, dynamic> post) {
    state = state.when(
      data: (posts) => AsyncData([post, ...posts]),
      error: (e, st) => state,
      loading: () => state,
    );
  }

  void updateCommentCount(String id) {
    state = state.when(
      data: (posts) {
        final updated =
            posts.map((post) {
              if (post['postID'] == id) {
                return {...post, 'totalComments': post['totalComments'] + 1};
              }
              return post;
            }).toList();
        return AsyncData(updated);
      },
      error: (e, st) => state,
      loading: () => state,
    );
  }

  void updateReactCount(String id) {
    state = state.when(
      data: (posts) {
        final updated =
            posts.map((post) {
              if (post['postID'] == id) {
                return {...post, 'reacts': post['reacts'] + 1};
              }
              return post;
            }).toList();
        return AsyncData(updated);
      },
      error: (e, st) => state,
      loading: () => state,
    );
  }

  List<Map<String, dynamic>> getPosts() {
    return state.maybeWhen(data: (posts) => posts, orElse: () => []);
  }

  void clearPosts() {
    state = const AsyncData([]);
  }
}
