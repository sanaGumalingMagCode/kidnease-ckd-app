import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../core/utils/logger.dart';

/// Client for USDA FoodData Central API
/// Free, no rate limits, 400K+ foods, government-verified data
class USDAApiClient {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _apiKey = 'DEMO_KEY'; // Replace with your key from https://fdc.nal.usda.gov/api-key-signup.html
  
  final http.Client _client;

  USDAApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Search for food in USDA database
  /// Returns null if not found or nutrients incomplete
  Future<NutritionalData?> searchFood(String query) async {
    if (query.trim().isEmpty) return null;

    try {
      logger.info('Searching USDA API', context: {'query': query});

      final url = Uri.parse('$_baseUrl/foods/search').replace(
        queryParameters: {
          'api_key': _apiKey,
          'query': query,
          'pageSize': '1', // Get best match only
          'dataType': 'Foundation,SR Legacy,Survey (FNDDS),Branded', // All data types
        },
      );

      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
          final food = data['foods'][0];
          final nutritionalData = _parseUSDAFood(food);
          
          if (nutritionalData != null && _hasRequiredNutrients(nutritionalData)) {
            logger.info('Found food in USDA', context: {
              'name': nutritionalData.productName,
              'hasAllNutrients': true,
            });
            return nutritionalData;
          } else {
            logger.warning('USDA food missing required CKD nutrients', context: {
              'name': food['description'],
            });
          }
        } else {
          logger.info('No foods found in USDA', context: {'query': query});
        }
      } else {
        logger.warning('USDA API error', context: {
          'statusCode': response.statusCode,
          'body': response.body,
        });
      }

      return null;
    } catch (e, stackTrace) {
      logger.error('Error searching USDA', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse USDA food item to NutritionalData
  NutritionalData? _parseUSDAFood(Map<String, dynamic> food) {
    try {
      final nutrients = food['foodNutrients'] as List? ?? [];
      
      // Extract nutrients by nutrient number
      double? sodium;
      double? potassium;
      double? phosphorus;
      double? protein;

      for (var nutrient in nutrients) {
        final nutrientNumber = nutrient['nutrientNumber']?.toString() ?? '';
        final nutrientName = nutrient['nutrientName']?.toString().toLowerCase() ?? '';
        final value = (nutrient['value'] as num?)?.toDouble();

        if (value == null) continue;

        // Sodium (nutrient #307)
        if (nutrientNumber == '307' || nutrientName.contains('sodium')) {
          sodium = value;
        }
        // Potassium (nutrient #306)
        else if (nutrientNumber == '306' || nutrientName.contains('potassium')) {
          potassium = value;
        }
        // Phosphorus (nutrient #305)
        else if (nutrientNumber == '305' || nutrientName.contains('phosphorus')) {
          phosphorus = value;
        }
        // Protein (nutrient #203)
        else if (nutrientNumber == '203' || nutrientName.contains('protein')) {
          protein = value;
        }
      }

      // Must have at least 3 of the 4 required nutrients
      if ([sodium, potassium, phosphorus, protein].where((n) => n != null).length < 3) {
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

  /// Check if nutritional data has all required CKD nutrients
  bool _hasRequiredNutrients(NutritionalData data) {
    // For CKD tracking, we need sodium, potassium, phosphorus
    // Protein is optional but nice to have
    return data.sodium > 0 || data.potassium > 0 || data.phosphorus > 0;
  }
}
