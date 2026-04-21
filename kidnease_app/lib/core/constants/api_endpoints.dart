/// API Endpoints for external services

class ApiEndpoints {
  // Gemini API
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1';
  static const String geminiModel = 'gemini-3.0-pro';
  static String get geminiGenerateContent =>
      '$geminiBaseUrl/models/$geminiModel:generateContent';

  // FatSecret API
  static const String fatSecretBaseUrl =
      'https://platform.fatsecret.com/rest/server.api';
  static const String fatSecretMethod = 'foods.search';

  // Timeouts
  static const Duration geminiTimeout = Duration(seconds: 10);
  static const Duration fatSecretTimeout = Duration(seconds: 5);
  static const Duration uploadTimeout = Duration(seconds: 30);

  // Retry Configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
}
