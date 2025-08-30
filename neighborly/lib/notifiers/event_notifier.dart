import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/models/event.dart';

final eventProvider =
    StateNotifierProvider<EventNotifier, AsyncValue<List<EventModel>>>(
      (ref) => EventNotifier(),
    );

class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  EventNotifier() : super(AsyncLoading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('approved', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();
      state = AsyncData(
        querySnapshot.docs.map((doc) {
          final event = doc.data();
          return EventModel.fromMap(event);
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> handleRefresh() async {
    state = AsyncLoading();
    loadEvents();
  }

  Future<void> addEvents(EventModel event, DocumentReference docRef) async {
    try {
      await docRef.set(event.toMap());
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
