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

/// Abstract interface for Gemini API operations
abstract class GeminiApiClient {
  /// Analyze food image and return nutritional assessment
  Future<GeminiResponse> analyzeFood({
    String? imageUrl,
    File? imageFile,
    required DietaryProfile userProfile,
    NutritionalData? fatSecretData,
  });
}

/// Implementation of GeminiApiClient
class GeminiApiClientImpl implements GeminiApiClient {
  final String _apiKey;
  final http.Client _client;

  GeminiApiClientImpl({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '',
        _client = client ?? http.Client();

  @override
  Future<GeminiResponse> analyzeFood({
    String? imageUrl,
    File? imageFile,
    required DietaryProfile userProfile,
    NutritionalData? fatSecretData,
  }) async {
    if (_apiKey.isEmpty) {
      throw const ApiException('Gemini API key not configured');
    }

    // Must provide either imageUrl or imageFile
    if (imageUrl == null && imageFile == null) {
      throw const ValidationException('Either imageUrl or imageFile must be provided');
    }

    int retryCount = 0;
    const maxRetries = ApiEndpoints.maxRetries;

    while (retryCount <= maxRetries) {
      try {
        logger.info('Analyzing food with Gemini API', context: {
          'hasImageUrl': imageUrl != null,
          'hasImageFile': imageFile != null,
          'attempt': retryCount + 1,
        });

        // Build the prompt
        final prompt = _buildPrompt(userProfile, fatSecretData);

        // Get image bytes
        final List<int> imageBytes;
        if (imageFile != null) {
          // Read from local file
          imageBytes = await imageFile.readAsBytes();
        } else {
          // Download from URL
          imageBytes = await _downloadImage(imageUrl!);
        }
        
        final base64Image = base64Encode(imageBytes);

        // Build request body
        final requestBody = {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 2048,
          }
        };

        // Make API request
        final uri = Uri.parse('${ApiEndpoints.geminiGenerateContent}?key=$_apiKey');
        
        final response = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(
              ApiEndpoints.geminiTimeout,
              onTimeout: () {
                throw NetworkException.timeout();
              },
            );

        // Handle rate limiting
        if (response.statusCode == 429) {
          logger.warning('Gemini API rate limit exceeded');
          
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(ApiEndpoints.retryDelay * retryCount);
            continue;
          }
          
          throw ApiException.rateLimitExceeded();
        }

        // Handle authentication errors
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw ApiException.unauthorized();
        }

        // Handle server errors
        if (response.statusCode >= 500) {
          logger.error('Gemini API server error', context: {
            'statusCode': response.statusCode,
          });
          
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(ApiEndpoints.retryDelay * retryCount);
            continue;
          }
          
          throw ApiException.serverError();
        }

        // Handle other errors
        if (response.statusCode != 200) {
          throw ApiException(
            'Gemini API error: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }

        // Parse response
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final geminiResponse = _parseGeminiResponse(jsonData);

        logger.info('Gemini API analysis complete', context: {
          'foodName': geminiResponse.detectedFoodName,
          'riskLevel': geminiResponse.riskLevel,
        });

        return geminiResponse;
      } on ApiException {
        rethrow;
      } on NetworkException {
        rethrow;
      } catch (e, stackTrace) {
        logger.error('Gemini API error', error: e, stackTrace: stackTrace, context: {
          'attempt': retryCount + 1,
        });

        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(ApiEndpoints.retryDelay * retryCount);
          continue;
        }

        throw ApiException('Gemini API failed: ${e.toString()}');
      }
    }

    throw const ApiException('Gemini API failed after all retries');
  }

  /// Build the prompt for Gemini API
  String _buildPrompt(DietaryProfile userProfile, NutritionalData? fatSecretData) {
    final buffer = StringBuffer();

    buffer.writeln('You are a renal nutrition assistant analyzing food for CKD patients.');
    buffer.writeln();
    buffer.writeln("User's Daily Limits:");
    buffer.writeln('- Sodium: ${userProfile.dailySodiumLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Potassium: ${userProfile.dailyPotassiumLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Phosphorus: ${userProfile.dailyPhosphorusLimit.toStringAsFixed(0)} mg');
    buffer.writeln('- Protein: ${userProfile.dailyProteinLimit.toStringAsFixed(1)} g');
    buffer.writeln();

    if (fatSecretData != null) {
      buffer.writeln('Commercial Product Data (for reference):');
      buffer.writeln('- Product: ${fatSecretData.productName}');
      buffer.writeln('- Sodium: ${fatSecretData.sodium.toStringAsFixed(0)} mg');
      buffer.writeln('- Potassium: ${fatSecretData.potassium.toStringAsFixed(0)} mg');
      buffer.writeln('- Phosphorus: ${fatSecretData.phosphorus.toStringAsFixed(0)} mg');
      buffer.writeln('- Protein: ${fatSecretData.protein.toStringAsFixed(1)} g');
      buffer.writeln('- Serving: ${fatSecretData.servingSize}');
      buffer.writeln();
    }

    buffer.writeln('Analyze this food image and extract:');
    buffer.writeln('1. Food name (be specific)');
    buffer.writeln('2. Nutritional content per serving (sodium, potassium, phosphorus, protein)');
    buffer.writeln('3. Risk assessment by comparing to user limits');
    buffer.writeln('4. Simple cause-and-effect explanation of renal impact');
    buffer.writeln('5. Filipino renal-friendly alternatives if high risk');
    buffer.writeln();
    buffer.writeln('Return ONLY valid JSON in this exact format:');
    buffer.writeln('{');
    buffer.writeln('  "detectedFoodName": "string",');
    buffer.writeln('  "sodium": number,');
    buffer.writeln('  "potassium": number,');
    buffer.writeln('  "phosphorus": number,');
    buffer.writeln('  "protein": number,');
    buffer.writeln('  "riskLevel": "High Risk" or "Safe",');
    buffer.writeln('  "explanationText": "string",');
    buffer.writeln('  "filipinoAlternatives": ["string", "string"]');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Parse Gemini API response
  GeminiResponse _parseGeminiResponse(Map<String, dynamic> jsonData) {
    try {
      // Extract text from Gemini response structure
      final candidates = jsonData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const JsonParseException('No candidates in Gemini response');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        throw const JsonParseException('No content in Gemini response');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw const JsonParseException('No parts in Gemini response');
      }

      final text = parts[0]['text'] as String?;
      if (text == null || text.isEmpty) {
        throw const JsonParseException('No text in Gemini response');
      }

      // Extract JSON from text (may be wrapped in markdown code blocks)
      final jsonText = _extractJson(text);
      final foodData = jsonDecode(jsonText) as Map<String, dynamic>;

      // Validate required fields
      _validateResponse(foodData);

      return GeminiResponse.fromJson(foodData);
    } catch (e, stackTrace) {
      logger.error('Error parsing Gemini response', error: e, stackTrace: stackTrace);
      throw JsonParseException('Failed to parse Gemini response: ${e.toString()}');
    }
  }

  /// Extract JSON from text (handles markdown code blocks)
  String _extractJson(String text) {
    // Remove markdown code blocks if present
    final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(1)!.trim();
    }

    // Remove generic code blocks
    final codeMatch = RegExp(r'```\s*([\s\S]*?)\s*```').firstMatch(text);
    if (codeMatch != null) {
      return codeMatch.group(1)!.trim();
    }

    // Return as-is if no code blocks
    return text.trim();
  }

  /// Validate Gemini response has required fields
  void _validateResponse(Map<String, dynamic> data) {
    final requiredFields = [
      'detectedFoodName',
      'sodium',
      'potassium',
      'phosphorus',
      'protein',
      'riskLevel',
      'explanationText',
    ];

    final missingFields = <String>[];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      throw ValidationException.missingFields(missingFields);
    }

    // Validate riskLevel enum
    final riskLevel = data['riskLevel'] as String;
    if (riskLevel != 'High Risk' && riskLevel != 'Safe') {
      throw ValidationException.invalidValue(
        'riskLevel',
        'must be "High Risk" or "Safe"',
      );
    }

    // Validate nutritional values are non-negative
    for (final nutrient in ['sodium', 'potassium', 'phosphorus', 'protein']) {
      final value = data[nutrient];
      if (value is num && value < 0) {
        throw ValidationException.invalidValue(
          nutrient,
          'must be non-negative',
        );
      }
    }
  }

  /// Download image from URL
  Future<List<int>> _downloadImage(String imageUrl) async {
    try {
      final response = await _client.get(Uri.parse(imageUrl)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw NetworkException.timeout();
        },
      );

      if (response.statusCode != 200) {
        throw StorageException('Failed to download image: ${response.statusCode}');
      }

      return response.bodyBytes;
    } catch (e, stackTrace) {
      logger.error('Error downloading image', error: e, stackTrace: stackTrace);
      throw StorageException('Failed to download image: ${e.toString()}');
    }
  }
}
