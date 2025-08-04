import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

Future<bool> verifyToken(String? idToken) async {
  final url = Uri.parse(ApiConfig.authUrl);
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'];
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}
