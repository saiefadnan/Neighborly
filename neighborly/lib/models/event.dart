class EventModel {
  final String title;
  final String description;
  final String imageUrl;
  final String joined;
  final DateTime date;
  final String location;
  final double lng;
  final double lat;
  final List<String> tags;

  EventModel({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.joined,
    required this.date,
    required this.location,
    required this.lng,
    required this.lat,
    required this.tags,
  });

  factory EventModel.fromMap(Map<String, dynamic> event) {
    return EventModel(
      title: event['title'],
      description: event['desc'],
      imageUrl: event['img'],
      joined: event['joined'],
      date: DateTime.parse(event['date']),
      location: event['location'],
      lng: event['lng'],
      lat: event['lat'],
      tags: List<String>.from(event['tags'] ?? []),
    );
  }
}

List<Map<String, dynamic>> events = [
  // {
  //   "title": "Tree Plantation",
  //   "desc": "Join us this Sunday to plant trees in the local park.",
  //   "img":
  //       "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651502/vitor-monthay-EkEdHarUPTs-unsplash_qsvwhr.jpg",
  //   "joined": "true",
  //   "date": "2025-08-10T09:30:00",
  //   "location": "Local Park, Dhaka",
  //   "lat": 23.8103,
  //   "lng": 90.4125,
  //   "tags": ["#Environment", "#Green", "#Community"],
  // },
  // {
  //   "title": "Invitation Party",
  //   "desc": "Celebrate the new season with your neighbors.",
  //   "img":
  //       "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80",
  //   "joined": "false",
  //   "date": "2025-08-15T19:00:00",
  //   "location": "Community Hall, Block B",
  //   "lat": 23.8150,
  //   "lng": 90.4250,
  //   "tags": ["#Party", "#Neighbors", "#Fun"],
  // },
  // {
  //   "title": "Health Camp",
  //   "desc": "Free health check-up and consultation.",
  //   "img":
  //       "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651567/tegan-mierle-fDostElVhN8-unsplash_kackpp.jpg",
  //   "joined": "false",
  //   "date": "2025-08-18T10:00:00",
  //   "location": "City Health Center",
  //   "lat": 23.7995,
  //   "lng": 90.4100,
  //   "tags": ["#Health", "#Wellness", "#FreeCheckup"],
  // },
  // {
  //   "title": "Community Clean-up",
  //   "desc": "Let’s clean our streets together!",
  //   "img":
  //       "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651680/zhang-kaiyv-QHFlhvQQFbQ-unsplash_dnlzqz.jpg",
  //   "joined": "true",
  //   "date": "2025-08-12T08:00:00",
  //   "location": "Street 7, Sector C",
  //   "lat": 23.8210,
  //   "lng": 90.4300,
  //   "tags": ["#CleanUp", "#Community", "#Together"],
  // },
  // {
  //   "title": "Book Swap",
  //   "desc": "Bring a book, take a book. Simple!",
  //   "img":
  //       "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80",
  //   "joined": "false",
  //   "date": "2025-08-20T15:00:00",
  //   "location": "Library Room, Community Center",
  //   "lat": 23.8050,
  //   "lng": 90.4170,
  //   "tags": ["#Books", "#Swap", "#Reading"],
  // },
  // {
  //   "title": "Potluck Dinner",
  //   "desc": "Share your favorite dish with the community.",
  //   "img":
  //       "https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80",
  //   "joined": "false",
  //   "date": "2025-08-25T18:30:00",
  //   "location": "Rooftop Garden, Building A",
  //   "lat": 23.8120,
  //   "lng": 90.4205,
  //   "tags": ["#Food", "#Community", "#Potluck"],
  // },
];
