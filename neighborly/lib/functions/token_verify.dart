import 'dart:convert';

import 'package:http/http.dart' as http;

Future<bool> verifyToken(String? idToken) async {

  final url = Uri.parse('http://192.168.1.183:4000/api/auth/signin/idtoken');

  
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
