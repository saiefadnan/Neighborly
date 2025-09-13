import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  String id;
  final String creatorId;
  final String title;
  final String description;
  final String imageUrl;
  final bool approved;
  final Timestamp createdAt;
  final String location;
  final double lng;
  final double lat;
  final double radius;
  final List<String> tags;
  final DateTime date;
  bool joined = false;

  EventModel({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.approved,
    required this.createdAt,
    required this.location,
    required this.lng,
    required this.lat,
    required this.radius,
    required this.tags,
    required this.date,
  });

  factory EventModel.fromMap(Map<String, dynamic> event) {
    return EventModel(
      id: event['id'] ?? '',
      creatorId: event['creatorId'] ?? '',
      title: event['title'] ?? '',
      description: event['desc'] ?? '',
      imageUrl: event['img'] ?? '',
      approved: event['approved'] ?? false,
      createdAt: event['createdAt'] ?? Timestamp.now(),
      location: event['location'] ?? '',
      lng: (event['lng'] ?? 0).toDouble(),
      lat: (event['lat'] ?? 0).toDouble(),
      radius: (event['radius'] ?? 0).toDouble(),
      tags: List<String>.from(event['tags'] ?? []),
      date:
          event['date'] != null
              ? (event['date'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap({bool apiCall = false}) {
    return {
      'id': id,
      'title': title,
      'creatorId': creatorId,
      'desc': description,
      'img': imageUrl,
      'approved': approved,
      'createdAt': !apiCall ? createdAt : createdAt.toDate().toIso8601String(),
      'location': location,
      'lng': lng,
      'lat': lat,
      'radius': radius,
      'tags': tags,
      'date': !apiCall ? Timestamp.fromDate(date) : date.toIso8601String(),
    };
  }
}
