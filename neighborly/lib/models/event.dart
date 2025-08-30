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
  });

  factory EventModel.fromMap(Map<String, dynamic> event) {
    return EventModel(
      id: event['id'],
      title: event['title'],
      description: event['desc'],
      imageUrl: event['img'],
      approved: event['approved'],
      createdAt: event['createdAt'],
      location: event['location'],
      lng: event['lng'],
      lat: event['lat'],
      raduis: event['raduis'],
      tags: List<String>.from(event['tags'] ?? []),
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
    };
  }
}
