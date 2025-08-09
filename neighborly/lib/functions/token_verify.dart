import 'dart:convert';

import 'package:http/http.dart' as http;

Future<bool> verifyToken(String? idToken) async {
<<<<<<< HEAD
  final url = Uri.parse('http://192.168.1.183:4000/api/auth/signin/idtoken');
=======
  final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/signin/idtoken');
>>>>>>> cde855b5e12ce190dd7378473800ec411ce36514
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
