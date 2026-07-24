import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/gemini_response.dart';
import '../models/nutritional_data.dart';

/// Abstract interface for AI food analysis operations
abstract class GeminiApiClient {
  Future<GeminiResponse> analyzeFood({
    String? imageUrl,
    File? imageFile,
    required DietaryProfile userProfile,
    NutritionalData? fatSecretData,
  });
}

/// Implementation using OpenRouter API (supports permanent API keys)
class GeminiApiClientImpl implements GeminiApiClient {
  final String _apiKey;
  final http.Client _client;

  GeminiApiClientImpl({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? dotenv.env['OPENROUTER_API_KEY'] ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        _client = client ?? http.Client();

  @override
  Future<GeminiResponse> analyzeFood({
    String? imageUrl,
    File? imageFile,
    required DietaryProfile userProfile,
    NutritionalData? fatSecretData,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ApiException('OpenRouter API key not configured. Add OPENROUTER_API_KEY to .env');
    }

    if (imageUrl == null && imageFile == null) {
      throw const ValidationException('Either imageUrl or imageFile must be provided');
    }

    int retryCount = 0;
    const maxRetries = ApiEndpoints.maxRetries;
    // Try primary model first, fall back to openrouter/free on 400
    final modelsToTry = [ApiEndpoints.openRouterModel, ApiEndpoints.openRouterModelFallback];
    int modelIndex = 0;

    while (retryCount <= maxRetries) {
      final currentModel = modelsToTry[modelIndex.clamp(0, modelsToTry.length - 1)];
      try {
        logger.info('Analyzing food with OpenRouter API', context: {
          'model': currentModel,
          'attempt': retryCount + 1,
        });

        final prompt = _buildPrompt(userProfile, fatSecretData);

        // Get base64 image
        final List<int> imageBytes;
        if (imageFile != null) {
          imageBytes = await imageFile.readAsBytes();
        } else {
          imageBytes = await _downloadImage(imageUrl!);
        }
        final base64Image = base64Encode(imageBytes);

        // OpenRouter uses OpenAI-compatible chat format
        final requestBody = {
          'model': currentModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.4,
        };

        final response = await _client
            .post(
              Uri.parse(ApiEndpoints.openRouterChat),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_apiKey',
                'HTTP-Referer': 'https://kidnease.app',
                'X-Title': 'Kidnease CKD Tracker',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              ApiEndpoints.geminiTimeout,
              onTimeout: () => throw NetworkException.timeout(),
            );

        if (response.statusCode == 429) {
          logger.warning('OpenRouter rate limit hit');
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(ApiEndpoints.retryDelay * retryCount);
            continue;
          }
          throw ApiException.rateLimitExceeded();
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw const ApiException('Invalid OpenRouter API key. Please check your OPENROUTER_API_KEY in .env');
        }

        // 400 means the model rejected the request - try fallback model
        if (response.statusCode == 400) {
          logger.warning('Model returned 400, switching to fallback model', context: {
            'failedModel': currentModel,
          });
          if (modelIndex < modelsToTry.length - 1) {
            modelIndex++;
            continue;
          }
          final errorBody = jsonDecode(response.body);
          final errorMsg = errorBody['error']?['message'] ?? 'Provider error';
          throw ApiException('Food analysis error: $errorMsg. Please try a different image.');
        }

        if (response.statusCode >= 500) {
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(ApiEndpoints.retryDelay * retryCount);
            continue;
          }
          throw ApiException.serverError();
        }

        if (response.statusCode != 200) {
          final errorBody = jsonDecode(response.body);
          final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
          throw ApiException('OpenRouter error ${response.statusCode}: $errorMsg');
        }

        // Parse OpenRouter response (OpenAI-compatible format)
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final geminiResponse = _parseOpenRouterResponse(jsonData);

        logger.info('Food analysis complete', context: {
          'foodName': geminiResponse.detectedFoodName,
          'riskLevel': geminiResponse.riskLevel,
        });

        return geminiResponse;

      } on ApiException {
        rethrow;
      } on NetworkException {
        rethrow;
      } catch (e, stackTrace) {
        logger.error('OpenRouter API error', error: e, stackTrace: stackTrace);
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(ApiEndpoints.retryDelay * retryCount);
          continue;
        }
        throw ApiException('Food analysis failed: ${e.toString()}');
      }
    }

    throw const ApiException('Food analysis failed after all retries');
  }

  String _buildPrompt(DietaryProfile userProfile, NutritionalData? fatSecretData) {
    final buffer = StringBuffer();
    buffer.writeln('You are a renal nutrition assistant analyzing food for a CKD (Chronic Kidney Disease) patient.');
    buffer.writeln('IMPORTANT: If the food is a Filipino dish (like Kare-Kare, Adobo, Sinigang, Tinola, Paksiw, Nilaga, Bistek, Caldereta, Menudo, Dinuguan, Kinilaw, Lechon, etc.), use its FILIPINO NAME in detectedFoodName, not an English translation.');
    buffer.writeln();
    buffer.writeln("Patient's Daily Dietary Limits:");
    buffer.writeln('- Sodium: ${userProfile.dailySodiumLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Potassium: ${userProfile.dailyPotassiumLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Phosphorus: ${userProfile.dailyPhosphorusLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Protein: ${userProfile.dailyProteinLimit.toStringAsFixed(1)} g');
    buffer.writeln();

    if (fatSecretData != null) {
      buffer.writeln('Nutritional Database Reference:');
      buffer.writeln('- Product: ${fatSecretData.productName}');
      buffer.writeln('- Sodium: ${fatSecretData.sodium.toStringAsFixed(0)} mg per ${fatSecretData.servingSize}');
      buffer.writeln('- Potassium: ${fatSecretData.potassium.toStringAsFixed(0)} mg');
      buffer.writeln('- Phosphorus: ${fatSecretData.phosphorus.toStringAsFixed(0)} mg');
      buffer.writeln('- Protein: ${fatSecretData.protein.toStringAsFixed(1)} g');
      buffer.writeln();
    }

    buffer.writeln('Analyze the food in this image and respond with ONLY a valid JSON object (no markdown, no extra text):');
    buffer.writeln('{');
    buffer.writeln('  "detectedFoodName": "specific food name",');
    buffer.writeln('  "sodium": <number in mg>,');
    buffer.writeln('  "potassium": <number in mg>,');
    buffer.writeln('  "phosphorus": <number in mg>,');
    buffer.writeln('  "protein": <number in grams>,');
    buffer.writeln('  "riskLevel": "High Risk" or "Safe",');
    buffer.writeln('  "explanationText": "brief explanation of why this is safe or risky for CKD kidneys",');
    buffer.writeln('  "filipinoAlternatives": ["alternative 1", "alternative 2"]');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('Rules:');
    buffer.writeln('- riskLevel is "High Risk" if ANY nutrient exceeds the patient limits, otherwise "Safe"');
    buffer.writeln('- filipinoAlternatives should be kidney-friendly Filipino foods if High Risk, empty array if Safe');
    buffer.writeln('- Estimate values for a typical serving size');
    buffer.writeln('- Return ONLY the JSON, nothing else');

    return buffer.toString();
  }

  GeminiResponse _parseOpenRouterResponse(Map<String, dynamic> jsonData) {
    try {
      // OpenAI-compatible response format
      final choices = jsonData['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const JsonParseException('No choices in OpenRouter response');
      }

      final message = choices[0]['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw const JsonParseException('No message in OpenRouter response');
      }

      final text = message['content'] as String?;
      if (text == null || text.isEmpty) {
        throw const JsonParseException('Empty content in OpenRouter response');
      }

      logger.info('Raw AI response received', context: {'preview': text.substring(0, text.length > 100 ? 100 : text.length)});

      // Extract JSON from response text
      final jsonText = _extractJson(text);
      final foodData = jsonDecode(jsonText) as Map<String, dynamic>;

      _validateResponse(foodData);

      return GeminiResponse.fromJson(foodData);
    } catch (e, stackTrace) {
      logger.error('Error parsing OpenRouter response', error: e, stackTrace: stackTrace);
      throw JsonParseException('Failed to parse food analysis response: ${e.toString()}');
    }
  }

  String _extractJson(String text) {
    // Try to find JSON block in markdown
    final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(text);
    if (jsonMatch != null) return jsonMatch.group(1)!.trim();

    final codeMatch = RegExp(r'```\s*([\s\S]*?)\s*```').firstMatch(text);
    if (codeMatch != null) return codeMatch.group(1)!.trim();

    // Try to find raw JSON object
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1).trim();
    }

    return text.trim();
  }

  void _validateResponse(Map<String, dynamic> data) {
    final requiredFields = ['detectedFoodName', 'sodium', 'potassium', 'phosphorus', 'protein', 'riskLevel', 'explanationText'];
    final missingFields = requiredFields.where((f) => !data.containsKey(f)).toList();
    if (missingFields.isNotEmpty) {
      throw ValidationException.missingFields(missingFields);
    }

    final riskLevel = data['riskLevel'] as String? ?? '';
    if (riskLevel != 'High Risk' && riskLevel != 'Safe') {
      // Auto-fix common variations
      if (riskLevel.toLowerCase().contains('high')) {
        data['riskLevel'] = 'High Risk';
      } else {
        data['riskLevel'] = 'Safe';
      }
    }

    // Ensure numeric fields are numbers
    for (final nutrient in ['sodium', 'potassium', 'phosphorus', 'protein']) {
      final value = data[nutrient];
      if (value is String) {
        data[nutrient] = double.tryParse(value) ?? 0.0;
      }
      if (data[nutrient] is num && (data[nutrient] as num) < 0) {
        data[nutrient] = 0.0;
      }
    }

    // Ensure filipinoAlternatives is a list
    if (!data.containsKey('filipinoAlternatives') || data['filipinoAlternatives'] == null) {
      data['filipinoAlternatives'] = [];
    }
  }

  Future<List<int>> _downloadImage(String imageUrl) async {
    try {
      final response = await _client.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StorageException('Failed to download image: ${response.statusCode}');
      }
      return response.bodyBytes;
    } catch (e) {
      throw StorageException('Failed to download image: ${e.toString()}');
    }
  }
}
