import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // static const String baseUrl =
  //     'http://<ip>:4000';
  // static const String baseUrl = 'https://your-backend-domain.com';

  static String baseUrl = dotenv.env['BASE_URL'] ?? 'http://<ip>:4000';

  // API endpoints
  static const String mapApiPath = '/api/map';
  static const String authApiPath = '/api/auth';
  static const String infosApiPath = '/api/infos';
  // Environment
  static const bool isDevelopment = true; // Set to false for production

  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
}
