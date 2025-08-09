class EventModel {
  final String title;
  final String description;
  final String imageUrl;
  final String joined;
  final DateTime date;
  final String location;
  final List<String> tags;

  EventModel({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.joined,
    required this.date,
    required this.location,
    required this.tags,
  });
}
