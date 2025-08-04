// API Configuration
// This file can be modified locally but should use environment variables in production

// Uncomment the line below and create local_config.dart for local development
// import 'local_config.dart';

class ApiConfig {
  // Priority order:
  // 1. Environment variable (for production/CI)
  // 2. Local config file (for development)
  // 3. Localhost fallback
  static String get baseUrl {
    // First try environment variable
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // Then try local config (uncomment the import above to use this)
    // try {
    //   return LocalConfig.backendUrl;
    // } catch (e) {
    //   // LocalConfig not found, use fallback
    // }

    // Fallback to localhost
    return 'http://localhost:4000';
  }

  // API endpoints
  static String get authUrl => '$baseUrl/api/auth/signin/idtoken';

  // Add more endpoints as needed
  // static String get postsUrl => '$baseUrl/api/posts';
  // static String get usersUrl => '$baseUrl/api/users';
}
