import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';
import '../providers/help_request_provider.dart';

/// Lightweight fetch layer mirroring map_service style for help list page.
class HelpListService {
  static String get _baseUrl => '${ApiConfig.baseUrl}${ApiConfig.mapApiPath}';

  static Future<String?> _token() async {
    final u = FirebaseAuth.instance.currentUser;
    return u?.getIdToken();
  }

  /// Fetch all requests (limit 100) then map into HelpRequestData objects.
  /// Classification (my vs community) is done later in provider using userId.
  static Future<List<HelpRequestData>> fetchAllHelpRequests() async {
    final token = await _token();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final uri = Uri.parse(
      '$_baseUrl/requests',
    ).replace(queryParameters: {'limit': '100'});
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resp.statusCode != 200) {
      throw Exception('Fetch failed (${resp.statusCode})');
    }
    print(resp.body);
    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final List list = decoded['data'] as List? ?? [];
    return list.map((e) => _fromApi(e as Map<String, dynamic>)).toList();
  }

  static HelpRequestData _fromApi(Map<String, dynamic> api) {
    final location = api['location'] ?? {};
    final lat = (location['latitude'] as num?)?.toDouble();
    final lng = (location['longitude'] as num?)?.toDouble();
    final createdAt = api['createdAt'] as String?;

    String timePosted = 'Just now';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          timePosted = 'Just now';
        } else if (diff.inMinutes < 60) {
          timePosted = '${diff.inMinutes} mins ago';
        } else if (diff.inHours < 24) {
          timePosted = '${diff.inHours} hours ago';
        } else {
          timePosted = '${diff.inDays} days ago';
        }
      } catch (_) {}
    }

    // Priority -> urgency mapping (capitalize)
    String urgency = 'General';
    final pr = (api['priority'] ?? '').toString().toLowerCase();
    if (pr == 'emergency')
      urgency = 'Emergency';
    else if (pr == 'urgent' || pr == 'high')
      urgency = 'Urgent';
    else
      urgency = 'General';

    final responses = (api['responses'] as List? ?? []);
    int responderCount = responses.length;
    bool respondedByCurrent = false; // provider may update after fetch

    return HelpRequestData(
      id: api['id'] ?? '',
      userId: api['userId'] ?? '',
      title: api['title'] ?? 'Help Request',
      description: api['description'] ?? '',
      helpType: api['type'] ?? 'General',
      urgency: urgency,
      location: api['address'] ?? '',
      distance: '0 km', // Distance calc not implemented yet
      timePosted: timePosted,
      requesterName: api['username'] ?? 'Anonymous',
      requesterImage: 'assets/images/dummy.png',
      contactNumber: api['phone'] ?? '',
      coordinates: (lat != null && lng != null) ? LatLng(lat, lng) : null,
      isResponded: respondedByCurrent,
      responderCount: responderCount,
    );
  }
}
