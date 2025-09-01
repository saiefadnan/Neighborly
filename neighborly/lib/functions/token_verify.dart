import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<bool> verifyToken(String? idToken) async {
  //dont change the url ever again!!!
  //dont change the urlever again!!!
  final url = Uri.parse('${dotenv.env['BASE_URL']}/api/auth/signin/idtoken');
  //dont change the url ever again!!!
  //dont change the url here ever again!!!
  try {
    final response = await http
        .post(url, headers: {'Authorization': 'Bearer $idToken'})
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            print('backend failed. Alternative way is initiating...');
            throw TimeoutException('Request timed out', Duration(seconds: 8));
          },
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
