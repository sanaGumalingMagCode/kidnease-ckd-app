/// API Endpoints for external services

class ApiEndpoints {
  // Gemini API (Free Tier - using v1beta with gemini-2.0-flash)
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.0-flash';
  static String get geminiGenerateContent =>
      '$geminiBaseUrl/models/$geminiModel:generateContent';

  // FatSecret API
  static const String fatSecretBaseUrl =
      'https://platform.fatsecret.com/rest/server.api';
  static const String fatSecretMethod = 'foods.search';

  // Timeouts
  static const Duration geminiTimeout = Duration(seconds: 30);  // Increased for new AQ. key format
  static const Duration fatSecretTimeout = Duration(seconds: 5);
  static const Duration uploadTimeout = Duration(seconds: 30);

  // Retry Configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
}
