import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../core/utils/logger.dart';

/// Client for USDA FoodData Central API
/// Free, no rate limits, 400K+ foods, government-verified data
class USDAApiClient {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _apiKey = '14ipfNjDrxxzR5wbyq5pt9ZceOhd2KVzmrk8i0El';

  final http.Client _client;

  USDAApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Search for food in USDA database with retry logic.
  /// Returns up to 20 results that have CKD nutrients.
  Future<List<NutritionalData>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        logger.info('Searching USDA API', context: {'query': query, 'attempt': attempt});

        final url = Uri.parse('$_baseUrl/foods/search').replace(
          queryParameters: {
            'api_key': _apiKey,
            'query': query,
            'pageSize': '25', // Fetch 25, filter down to those with nutrients
            'dataType': 'Foundation,SR Legacy,Survey (FNDDS),Branded',
          },
        );

        final response = await _client.get(url).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            logger.warning('USDA API timeout', context: {'attempt': attempt});
            return http.Response('Timeout', 408);
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final foods = data['foods'] as List? ?? [];

          if (foods.isEmpty) {
            logger.info('No foods found in USDA', context: {'query': query});
            return [];
          }

          // Parse all results and keep those with usable CKD nutrients
          final results = <NutritionalData>[];
          for (final food in foods) {
            final nutritionalData = _parseUSDAFood(food);
            if (nutritionalData != null && _hasRequiredNutrients(nutritionalData)) {
              results.add(nutritionalData);
              if (results.length >= 20) break; // Cap at 20 results
            }
          }

          logger.info('USDA returned results', context: {'count': results.length, 'query': query});
          return results;

        } else if (response.statusCode == 408 || response.statusCode == 503 || response.statusCode == 504) {
          logger.warning('USDA API transient error, will retry', context: {
            'statusCode': response.statusCode,
            'attempt': attempt,
          });
          if (attempt < 2) {
            await Future.delayed(const Duration(milliseconds: 800));
            continue;
          }
        } else {
          logger.warning('USDA API error', context: {'statusCode': response.statusCode});
          return [];
        }
      } catch (e, stackTrace) {
        logger.error('Error searching USDA', error: e, stackTrace: stackTrace, context: {'attempt': attempt});
        if (attempt < 2) {
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
      }
    }

    return [];
  }

  /// Legacy single-result search (kept for compatibility)
  Future<NutritionalData?> searchFood(String query) async {
    final results = await searchFoods(query);
    return results.isEmpty ? null : results.first;
  }

  /// Parse a USDA food item into NutritionalData.
  NutritionalData? _parseUSDAFood(Map<String, dynamic> food) {
    try {
      final nutrients = food['foodNutrients'] as List? ?? [];

      double? sodium;
      double? potassium;
      double? phosphorus;
      double? protein;

      for (var nutrient in nutrients) {
        final nutrientNumber = nutrient['nutrientNumber']?.toString() ?? '';
        final nutrientName = nutrient['nutrientName']?.toString().toLowerCase() ?? '';
        final value = (nutrient['value'] as num?)?.toDouble();

        if (value == null || value <= 0) continue;

        if (nutrientNumber == '307' || nutrientName.contains('sodium')) {
          sodium = value;
        } else if (nutrientNumber == '306' || nutrientName.contains('potassium')) {
          potassium = value;
        } else if (nutrientNumber == '305' || nutrientName.contains('phosphorus')) {
          phosphorus = value;
        } else if (nutrientNumber == '203' || nutrientName.contains('protein')) {
          protein = value;
        }
      }

      final nutrientCount = [sodium, potassium, phosphorus, protein]
          .where((n) => n != null && n > 0)
          .length;

      if (nutrientCount == 0) {
        logger.warning('USDA food has no nutrients', context: {'name': food['description']});
        return null;
      }

      return NutritionalData(
        productName: '${food['description'] ?? 'Unknown'} [USDA]',
        servingSize: '100g',
        sodium: sodium ?? 0.0,
        potassium: potassium ?? 0.0,
        phosphorus: phosphorus ?? 0.0,
        protein: protein ?? 0.0,
      );
    } catch (e) {
      logger.error('Error parsing USDA food', error: e);
      return null;
    }
  }

  bool _hasRequiredNutrients(NutritionalData data) {
    return data.sodium > 0 ||
        data.potassium > 0 ||
        data.phosphorus > 0 ||
        data.protein > 0;
  }
}
