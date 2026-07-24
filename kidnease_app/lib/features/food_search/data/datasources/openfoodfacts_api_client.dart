import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../core/utils/logger.dart';

/// Client for Open Food Facts API
/// Free, no rate limits, 2M+ foods, global packaged products
class OpenFoodFactsApiClient {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';
  
  final http.Client _client;

  OpenFoodFactsApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Search for food in Open Food Facts database
  /// Returns null if not found or CKD nutrients incomplete
  Future<NutritionalData?> searchFood(String query) async {
    if (query.trim().isEmpty) return null;

    try {
      logger.info('Searching Open Food Facts API', context: {'query': query});

      final url = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'search_terms': query,
          'page_size': '1',
          'fields': 'product_name,nutriments,serving_size',
          'sort_by': 'popularity', // Get most popular/verified first
        },
      );

      final response = await _client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('Timeout', 408),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['products'] != null && (data['products'] as List).isNotEmpty) {
          final product = data['products'][0];
          final nutritionalData = _parseOpenFoodFactsProduct(product);
          
          if (nutritionalData != null && _hasRequiredNutrients(nutritionalData)) {
            logger.info('Found food in Open Food Facts', context: {
              'name': nutritionalData.productName,
              'hasAllNutrients': true,
            });
            return nutritionalData;
          } else {
            logger.warning('Open Food Facts product missing required CKD nutrients', context: {
              'name': product['product_name'],
            });
          }
        } else {
          logger.info('No products found in Open Food Facts', context: {'query': query});
        }
      } else {
        logger.warning('Open Food Facts API error', context: {
          'statusCode': response.statusCode,
        });
      }

      return null;
    } catch (e, stackTrace) {
      logger.error('Error searching Open Food Facts', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse Open Food Facts product to NutritionalData
  NutritionalData? _parseOpenFoodFactsProduct(Map<String, dynamic> product) {
    try {
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
      
      // Extract nutrients (Open Food Facts uses per 100g by default)
      // Values can be in different units, normalize to mg/g
      
      // Sodium (in mg or g)
      double? sodium = _extractNutrient(nutriments, ['sodium', 'salt']);
      if (sodium != null && sodium < 10) {
        // Probably in grams, convert to mg
        sodium = sodium * 1000;
      }
      
      // Potassium (in mg or g)
      double? potassium = _extractNutrient(nutriments, ['potassium']);
      if (potassium != null && potassium < 10) {
        potassium = potassium * 1000;
      }
      
      // Phosphorus (in mg or g)
      double? phosphorus = _extractNutrient(nutriments, ['phosphorus', 'phosphorous']);
      if (phosphorus != null && phosphorus < 10) {
        phosphorus = phosphorus * 1000;
      }
      
      // Protein (in g)
      double? protein = _extractNutrient(nutriments, ['proteins', 'protein']);

      // Check if we have enough data for CKD tracking
      final nutrientCount = [sodium, potassium, phosphorus, protein]
          .where((n) => n != null && n > 0)
          .length;
          
      if (nutrientCount < 2) {
        // Not enough nutrient data for CKD tracking
        return null;
      }

      return NutritionalData(
        productName: '${product['product_name'] ?? 'Unknown'} [OpenFoodFacts]',
        servingSize: product['serving_size'] ?? '100g',
        sodium: sodium ?? 0.0,
        potassium: potassium ?? 0.0,
        phosphorus: phosphorus ?? 0.0,
        protein: protein ?? 0.0,
      );
    } catch (e) {
      logger.error('Error parsing Open Food Facts product', error: e);
      return null;
    }
  }

  /// Extract nutrient value from nutriments object
  /// Tries multiple possible keys
  double? _extractNutrient(Map<String, dynamic> nutriments, List<String> possibleKeys) {
    for (var key in possibleKeys) {
      // Try exact key
      var value = nutriments[key];
      if (value != null) {
        return (value as num).toDouble();
      }
      
      // Try with _100g suffix
      value = nutriments['${key}_100g'];
      if (value != null) {
        return (value as num).toDouble();
      }
      
      // Try with _serving suffix
      value = nutriments['${key}_serving'];
      if (value != null) {
        // Convert to per 100g if we have serving size
        final servingSize = nutriments['serving_size'];
        if (servingSize != null) {
          // This would need parsing, for now just use the value
          return (value as num).toDouble();
        }
      }
    }
    return null;
  }

  /// Check if nutritional data has enough CKD nutrients
  bool _hasRequiredNutrients(NutritionalData data) {
    // For CKD tracking, we need at least 2 of the 3 key minerals
    final keyMinerals = [
      data.sodium > 0,
      data.potassium > 0,
      data.phosphorus > 0,
    ].where((hasIt) => hasIt).length;
    
    return keyMinerals >= 2; // At least 2 minerals must be present
  }
}
