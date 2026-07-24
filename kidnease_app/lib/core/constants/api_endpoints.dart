/// API Endpoints for external services

class ApiEndpoints {
  // OpenRouter API (replaces Gemini - permanent API key, free tier available)
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  // Free Models Router - automatically picks a working free vision model
  static const String openRouterModel = 'openrouter/free';
  // Explicit fallback if router fails
  static const String openRouterModelFallback = 'meta-llama/llama-3.2-11b-vision-instruct:free';
  static String get openRouterChat => '$openRouterBaseUrl/chat/completions';

  // FatSecret API
  static const String fatSecretBaseUrl =
      'https://platform.fatsecret.com/rest/server.api';
  static const String fatSecretMethod = 'foods.search';

  // Timeouts
  static const Duration geminiTimeout = Duration(seconds: 30);
  static const Duration fatSecretTimeout = Duration(seconds: 5);
  static const Duration uploadTimeout = Duration(seconds: 30);

  // Retry Configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
}
