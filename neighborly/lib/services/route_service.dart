import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  // Using OpenRouteService - free tier with 2000 requests/day
  static const String _baseUrl = 'https://api.openrouteservice.org/v2';
  static const String _apiKey =
      '5b3ce3597851110001cf6248a96c3e5c0e524b0281f5da5deb8c9c17'; // Free demo key

  static Future<Map<String, dynamic>?> getRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'driving-car', // driving-car, walking, cycling-regular
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/directions/$profile?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}&format=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final properties = feature['properties'];
          final geometry = feature['geometry'];

          return {
            'success': true,
            'distance': properties['segments'][0]['distance'], // in meters
            'duration': properties['segments'][0]['duration'], // in seconds
            'coordinates': geometry['coordinates'], // List of [lng, lat] points
            'instructions': _extractInstructions(
              properties['segments'][0]['steps'],
            ),
          };
        }
      }

      return {'success': false, 'error': 'No route found'};
    } catch (e) {
      print('Route service error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<List<Map<String, dynamic>>> getMultipleRoutes({
    required LatLng start,
    required LatLng end,
  }) async {
    List<Map<String, dynamic>> routes = [];

    // Try different transportation modes
    List<String> profiles = ['driving-car', 'walking', 'cycling-regular'];
    List<String> profileNames = ['Driving', 'Walking', 'Cycling'];

    for (int i = 0; i < profiles.length; i++) {
      final route = await getRoute(
        start: start,
        end: end,
        profile: profiles[i],
      );
      if (route != null && route['success'] == true) {
        route['mode'] = profileNames[i];
        route['profile'] = profiles[i];
        routes.add(route);
      }
    }

    return routes;
  }

  static List<String> _extractInstructions(List<dynamic> steps) {
    List<String> instructions = [];

    for (var step in steps) {
      String instruction = step['instruction'] ?? '';
      double distance = (step['distance'] ?? 0).toDouble();

      if (instruction.isNotEmpty) {
        String distanceText =
            distance > 1000
                ? '${(distance / 1000).toStringAsFixed(1)} km'
                : '${distance.toInt()} m';
        instructions.add('$instruction ($distanceText)');
      }
    }

    return instructions;
  }

  // Fallback method using local calculation for basic directions
  static Map<String, dynamic> getBasicDirections({
    required LatLng start,
    required LatLng end,
    required String destinationAddress,
  }) {
    // Calculate straight-line distance
    double distance = _calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Calculate bearing
    double bearing = _calculateBearing(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    String direction = _bearingToDirection(bearing);

    List<String> basicInstructions = [
      'Head $direction towards the destination',
      'Continue for approximately ${(distance * 1000).toInt()} meters',
      'You will arrive at $destinationAddress',
    ];

    return {
      'success': true,
      'distance': distance * 1000, // Convert to meters
      'duration': (distance * 1000) / 1.4, // Assume 1.4 m/s walking speed
      'instructions': basicInstructions,
      'mode': 'Basic Directions',
      'isBasic': true,
    };
  }

  // Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Calculate bearing between two points
  static double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    double dLon = _degreesToRadians(lon2 - lon1);
    lat1 = _degreesToRadians(lat1);
    lat2 = _degreesToRadians(lat2);

    double y = math.sin(dLon) * math.cos(lat2);
    double x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
  static double _radiansToDegrees(double radians) => radians * (180 / math.pi);

  static String _bearingToDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing >= 22.5 && bearing < 67.5) return 'Northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'East';
    if (bearing >= 112.5 && bearing < 157.5) return 'Southeast';
    if (bearing >= 157.5 && bearing < 202.5) return 'South';
    if (bearing >= 202.5 && bearing < 247.5) return 'Southwest';
    if (bearing >= 247.5 && bearing < 292.5) return 'West';
    if (bearing >= 292.5 && bearing < 337.5) return 'Northwest';
    return 'North';
  }
}
