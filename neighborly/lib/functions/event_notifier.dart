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
          await FirebaseFirestore.instance.collection('events').get();
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
}
