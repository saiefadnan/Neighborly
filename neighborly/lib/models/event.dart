import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final bool approved;
  final Timestamp createdAt;
  final String location;
  final double lng;
  final double lat;
  final double raduis;
  final List<String> tags;
  final DateTime date;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.approved,
    required this.createdAt,
    required this.location,
    required this.lng,
    required this.lat,
    required this.raduis,
    required this.tags,
    required this.date,
  });

  factory EventModel.fromMap(Map<String, dynamic> event) {
    return EventModel(
      id: event['id'] ?? '',
      title: event['title'] ?? '',
      description: event['desc'] ?? '',
      imageUrl: event['img'] ?? '',
      approved: event['approved'] ?? false,
      createdAt: event['createdAt'] ?? Timestamp.now(),
      location: event['location'] ?? '',
      lng: (event['lng'] ?? 0).toDouble(),
      lat: (event['lat'] ?? 0).toDouble(),
      raduis: (event['raduis'] ?? 0).toDouble(),
      tags: List<String>.from(event['tags'] ?? []),
      date:
          event['date'] != null
              ? (event['date'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'desc': description,
      'img': imageUrl,
      'approved': approved,
      'createdAt': createdAt,
      'location': location,
      'lng': lng,
      'lat': lat,
      'raduis': raduis,
      'tags': tags,
      'date': Timestamp.fromDate(date),
    };
  }
}
