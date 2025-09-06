import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<EventModel> _filterEventsByLocation(
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

      // Check if user is within the event's radius
      return distance <= event.raduis;
    }).toList();
  }

  Future<void> loadEvents() async {
    try {
      final url = Uri.parse(
        '${dotenv.env['BASE_URL']}${ApiConfig.eventApiPath}/load/nearby/events',
      );

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allEvents =
            (data['eventData'] as List<Map<String, dynamic>>)
                .map((event) => EventModel.fromMap(event))
                .toList();

        final userLocation = await _getCurrentLocation();

        if (userLocation != null) {
          // Filter events based on user location and event radius
          final nearbyEvents = _filterEventsByLocation(allEvents, userLocation);
          state = AsyncData(nearbyEvents);
        } else {
          // If location is not available, show all events
          state = AsyncData(allEvents);
        }
      }
    } catch (e) {
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

      final allEvents =
          querySnapshot.docs.map((doc) {
            final event = doc.data();
            return EventModel.fromMap(event);
          }).toList();

      // Get user's current location and filter events
      final userLocation = await _getCurrentLocation();

      if (userLocation != null) {
        // Filter events based on user location and event radius
        final nearbyEvents = _filterEventsByLocation(allEvents, userLocation);
        state = AsyncData(nearbyEvents);
      } else {
        // If location is not available, show all events
        state = AsyncData(allEvents);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Load all events without location filtering (for admin or debugging)
  Future<void> loadAllEvents() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('approved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      final allEvents =
          querySnapshot.docs.map((doc) {
            final event = doc.data();
            return EventModel.fromMap(event);
          }).toList();

      state = AsyncData(allEvents);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

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
