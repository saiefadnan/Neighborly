import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neighborly/config/api_config.dart';
import 'package:neighborly/models/event.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

final eventProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>(
      (ref) => EventNotifier(),
    );

class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  EventNotifier() : super(AsyncLoading()) {
    loadEvents();
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Get user's current location
  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // Filter events based on user location and event radius
  List<EventModel> _filterEventsByJoinedOrLocation(
    List<String> joinedEvents,
    List<EventModel> events,
    Position userLocation,
  ) {
    return events.where((event) {
      double distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        event.lat,
        event.lng,
      );

      event.joined = joinedEvents.contains(event.id);
      // Check if user is within the event's radius
      return distance <= event.radius || joinedEvents.contains(event.id);
    }).toList();
  }

  Future<void> loadEvents() async {
    try {
      final url = Uri.parse(
        '${dotenv.env['BASE_URL']}${ApiConfig.eventApiPath}/load/nearby/events',
      );
      print('Loading events from API...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'uid': FirebaseAuth.instance.currentUser!.uid}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response: $data'); // Debug log to see the structure

        final allEvents =
            (data['eventData'] as List<dynamic>)
                .map((eventData) {
                  try {
                    // Convert timestamp fields if they come as Map from API
                    final eventMap = Map<String, dynamic>.from(eventData);

                    // Handle createdAt timestamp conversion
                    if (eventMap['createdAt'] is Map) {
                      final timestampMap =
                          eventMap['createdAt'] as Map<String, dynamic>;
                      eventMap['createdAt'] = Timestamp(
                        timestampMap['_seconds'] ??
                            timestampMap['seconds'] ??
                            0,
                        timestampMap['_nanoseconds'] ??
                            timestampMap['nanoseconds'] ??
                            0,
                      );
                    }

                    // Handle date timestamp conversion
                    if (eventMap['date'] is Map) {
                      final timestampMap =
                          eventMap['date'] as Map<String, dynamic>;
                      eventMap['date'] = Timestamp(
                        timestampMap['_seconds'] ??
                            timestampMap['seconds'] ??
                            0,
                        timestampMap['_nanoseconds'] ??
                            timestampMap['nanoseconds'] ??
                            0,
                      );
                    }

                    return EventModel.fromMap(eventMap);
                  } catch (e) {
                    print('Error parsing event: $e');
                    print('Event data: $eventData');
                    return null;
                  }
                })
                .where((event) => event != null)
                .cast<EventModel>()
                .toList();

        final joinedEvents =
            (data['joinedIds'] as List<dynamic>)
                .map((id) => id as String)
                .toList();

        final userLocation = await _getCurrentLocation();

        if (userLocation != null) {
          // Filter events based on user location and event radius
          final nearbyEvents = _filterEventsByJoinedOrLocation(
            joinedEvents,
            allEvents,
            userLocation,
          );
          state = AsyncData(nearbyEvents);
        }
        // else {
        //   // If location is not available, show all events
        //   state = AsyncData(allEvents);
        // }
      }
    } catch (e) {
      print('Error loading events from API: $e');
      await backupLoadEvents();
    }
  }

  Future<void> backupLoadEvents() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('approved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();
      final queryJoinedSnapshot =
          await FirebaseFirestore.instance
              .collectionGroup('participants')
              .where(
                'memberId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get();

      final joinedEvents =
          queryJoinedSnapshot.docs
              .map((doc) => doc['eventId'] as String)
              .toList();

      final allEvents =
          querySnapshot.docs.map((doc) {
            final event = doc.data();
            return EventModel.fromMap(event);
          }).toList();

      final userLocation = await _getCurrentLocation();

      if (userLocation != null) {
        // Filter events based on user location and event radius
        final joinedOrnearbyEvents = _filterEventsByJoinedOrLocation(
          joinedEvents,
          allEvents,
          userLocation,
        );
        state = AsyncData(joinedOrnearbyEvents);
      } else {
        // If location is not available, show all events
        state = AsyncData(allEvents);
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncError(e, st);
      print('Error loading events from Firestore: $e');
    }
  }

  // Load all events without location filtering (for admin or debugging)
  // Future<void> loadAllEvents() async {
  //   try {
  //     final querySnapshot =
  //         await FirebaseFirestore.instance
  //             .collection('events')
  //             .where('approved', isEqualTo: true)
  //             .orderBy('createdAt', descending: true)
  //             .get();

  //     final allEvents =
  //         querySnapshot.docs.map((doc) {
  //           final event = doc.data();
  //           return EventModel.fromMap(event);
  //         }).toList();

  //     state = AsyncData(allEvents);
  //   } catch (e, st) {
  //     state = AsyncError(e, st);
  //   }
  // }

  Future<void> handleRefresh() async {
    state = const AsyncLoading();
    await loadEvents(); // This will now include location-based filtering
  }

  Future<void> storeEvents(EventModel event) async {
    print('Storing event...');
    try {
      final url = Uri.parse(
        '${dotenv.env['BASE_URL']}${ApiConfig.eventApiPath}/store/event',
      );
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'event': event.toMap(apiCall: true)}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        event.id = data['eventId'];
        print('Event stored successfully: $data');
      }
    } catch (e) {
      await backupStoreEvents(event);
    }
  }

  Future<void> backupStoreEvents(EventModel event) async {
    try {
      print('Backing up event to Firestore...');
      final docRef = FirebaseFirestore.instance.collection('events').doc();
      event.id = docRef.id;
      await docRef.set({...event.toMap(), 'id': docRef.id});
    } catch (e, st) {
      print('Error storing event to Firestore: $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> addEvents(EventModel event) async {
    try {
      state = state.when(
        data: (events) => AsyncData([event, ...events]),
        error: (e, st) => state,
        loading: () => state,
      );
    } catch (e, st) {
      // Handle errors properly
      state = AsyncError(e, st);
    }
  }
}
