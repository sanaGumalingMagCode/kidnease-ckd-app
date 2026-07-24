import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../core/utils/logger.dart';

/// Client for Open Food Facts API
/// Free, no rate limits, 2M+ foods, global packaged products
class OpenFoodFactsApiClient {
  // v0 search endpoint is more stable than v2
  static const String _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  final http.Client _client;

  OpenFoodFactsApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Search for food in Open Food Facts database with retry logic.
  /// Returns up to 20 results that have CKD nutrients.
  Future<List<NutritionalData>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        logger.info('Searching Open Food Facts API', context: {'query': query, 'attempt': attempt});

        final url = Uri.parse(_searchUrl).replace(
          queryParameters: {
            'search_terms': query,
            'search_simple': '1',
            'action': 'process',
            'json': '1',
            'page_size': '25',
            'fields': 'product_name,nutriments,serving_size',
            'sort_by': 'popularity',
          },
        );

        final response = await _client.get(
          url,
          headers: {'User-Agent': 'KidnEase CKD Tracker - Flutter App'},
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            logger.warning('Open Food Facts API timeout', context: {'attempt': attempt});
            return http.Response('Timeout', 408);
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final products = data['products'] as List? ?? [];

          if (products.isEmpty) {
            logger.info('No products found in Open Food Facts', context: {'query': query});
            return [];
          }

          final results = <NutritionalData>[];
          for (final product in products) {
            final nutritionalData = _parseProduct(product);
            if (nutritionalData != null && _hasRequiredNutrients(nutritionalData)) {
              results.add(nutritionalData);
              if (results.length >= 20) break;
            }
          }

          logger.info('Open Food Facts returned results', context: {'count': results.length});
          return results;

        } else if (response.statusCode == 503 || response.statusCode == 408 || response.statusCode == 504) {
          logger.warning('Open Food Facts transient error, will retry', context: {
            'statusCode': response.statusCode,
            'attempt': attempt,
          });
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
        } else {
          logger.warning('Open Food Facts API error', context: {'statusCode': response.statusCode});
          return [];
        }
      } catch (e, stackTrace) {
        logger.error('Error searching Open Food Facts', error: e, stackTrace: stackTrace, context: {'attempt': attempt});
        if (attempt < 3) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
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

  NutritionalData? _parseProduct(Map<String, dynamic> product) {
    try {
      final name = (product['product_name'] as String? ?? '').trim();
      if (name.isEmpty) return null;

      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      // Sodium - try multiple keys, handle both mg and g
      double? sodium = _extract(nutriments, ['sodium_100g', 'sodium', 'salt_100g', 'salt']);
      if (sodium != null && sodium < 5) sodium = sodium * 1000; // g → mg

      // Potassium
      double? potassium = _extract(nutriments, ['potassium_100g', 'potassium']);
      if (potassium != null && potassium < 5) potassium = potassium * 1000;

      // Phosphorus
      double? phosphorus = _extract(nutriments, ['phosphorus_100g', 'phosphorus', 'phosphorous_100g', 'phosphorous']);
      if (phosphorus != null && phosphorus < 5) phosphorus = phosphorus * 1000;

      // Protein
      double? protein = _extract(nutriments, ['proteins_100g', 'proteins', 'protein_100g', 'protein']);

      final nutrientCount = [sodium, potassium, phosphorus, protein]
          .where((n) => n != null && n > 0)
          .length;

      if (nutrientCount == 0) return null;

      return NutritionalData(
        productName: '$name [Open Food Facts]',
        servingSize: product['serving_size'] as String? ?? '100g',
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

  double? _extract(Map<String, dynamic> nutriments, List<String> keys) {
    for (final key in keys) {
      final v = nutriments[key];
      if (v != null) return (v as num).toDouble();
    }
    return null;
  }

  bool _hasRequiredNutrients(NutritionalData data) {
    // Accept if at least 1 CKD-relevant nutrient is present
    return data.sodium > 0 ||
        data.potassium > 0 ||
        data.phosphorus > 0 ||
        data.protein > 0;
  }
}
