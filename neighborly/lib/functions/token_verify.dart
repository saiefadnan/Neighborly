import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<bool> verifyToken(String? idToken) async {
  final baseUrl = dotenv.env['BASE_URL'];
  final url = Uri.parse('${baseUrl}/api/auth/signin/idtoken');

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
