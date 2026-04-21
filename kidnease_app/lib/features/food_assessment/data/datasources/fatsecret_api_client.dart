import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/nutritional_data.dart';

/// Abstract interface for FatSecret API operations
abstract class FatSecretApiClient {
  /// Search for a product and return nutritional data
  Future<NutritionalData?> searchProduct(String productName);
}

/// Implementation of FatSecretApiClient with OAuth 1.0 authentication
class FatSecretApiClientImpl implements FatSecretApiClient {
  final String _consumerKey;
  final String _consumerSecret;
  final http.Client _client;

  FatSecretApiClientImpl({
    String? consumerKey,
    String? consumerSecret,
    http.Client? client,
  })  : _consumerKey = consumerKey ?? dotenv.env['FATSECRET_KEY'] ?? '',
        _consumerSecret = consumerSecret ?? dotenv.env['FATSECRET_SECRET'] ?? '',
        _client = client ?? http.Client();

  @override
  Future<NutritionalData?> searchProduct(String productName) async {
    if (_consumerKey.isEmpty || _consumerSecret.isEmpty) {
      logger.warning('FatSecret API credentials not configured');
      return null; // Graceful degradation
    }

    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        logger.info('Searching FatSecret API', context: {
          'productName': productName,
          'attempt': retryCount + 1,
        });

        // Build OAuth parameters
        final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
        final nonce = _generateNonce();

        final params = {
          'method': ApiEndpoints.fatSecretMethod,
          'search_expression': productName,
          'format': 'json',
          'oauth_consumer_key': _consumerKey,
          'oauth_signature_method': 'HMAC-SHA1',
          'oauth_timestamp': timestamp,
          'oauth_nonce': nonce,
          'oauth_version': '1.0',
        };

        // Generate OAuth signature
        final signature = _generateSignature('GET', ApiEndpoints.fatSecretBaseUrl, params);
        params['oauth_signature'] = signature;

        // Build URL with query parameters
        final uri = Uri.parse(ApiEndpoints.fatSecretBaseUrl).replace(
          queryParameters: params,
        );

        // Make request with timeout
        final response = await _client.get(uri).timeout(
          ApiEndpoints.fatSecretTimeout,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );

        // Handle rate limiting
        if (response.statusCode == 429) {
          logger.warning('FatSecret API rate limit exceeded');
          
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
          
          return null; // Graceful degradation
        }

        // Handle authentication errors
        if (response.statusCode == 401) {
          logger.error('FatSecret API authentication failed', context: {
            'statusCode': response.statusCode,
          });
          return null; // Graceful degradation
        }

        // Handle other errors
        if (response.statusCode != 200) {
          logger.error('FatSecret API error', context: {
            'statusCode': response.statusCode,
            'body': response.body,
          });
          return null; // Graceful degradation
        }

        // Parse response
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check if foods were found
        if (!jsonData.containsKey('foods') || jsonData['foods'] == null) {
          logger.info('No products found in FatSecret', context: {
            'productName': productName,
          });
          return null; // No match found (not an error)
        }

        final foods = jsonData['foods'] as Map<String, dynamic>;
        if (!foods.containsKey('food') || foods['food'] == null) {
          return null;
        }

        // Get first food item
        final foodList = foods['food'];
        final firstFood = foodList is List && foodList.isNotEmpty
            ? foodList[0]
            : foodList;

        if (firstFood == null) {
          return null;
        }

        // Parse nutritional data
        final nutritionalData = NutritionalData.fromJson(firstFood as Map<String, dynamic>);

        logger.info('FatSecret product found', context: {
          'productName': nutritionalData.productName,
          'sodium': nutritionalData.sodium,
        });

        return nutritionalData;
      } on NetworkException {
        rethrow;
      } catch (e, stackTrace) {
        logger.error('FatSecret API error', error: e, stackTrace: stackTrace, context: {
          'productName': productName,
          'attempt': retryCount + 1,
        });

        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }

        // Graceful degradation - return null instead of throwing
        return null;
      }
    }

    return null;
  }

  /// Generate OAuth signature using HMAC-SHA1
  String _generateSignature(String method, String url, Map<String, String> params) {
    // Sort parameters
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Build parameter string
    final paramString = sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    // Build signature base string
    final baseString = [
      method.toUpperCase(),
      Uri.encodeComponent(url),
      Uri.encodeComponent(paramString),
    ].join('&');

    // Generate signing key
    final signingKey = '${Uri.encodeComponent(_consumerSecret)}&';

    // Generate HMAC-SHA1 signature
    final hmac = Hmac(sha1, utf8.encode(signingKey));
    final digest = hmac.convert(utf8.encode(baseString));
    
    return base64.encode(digest.bytes);
  }

  /// Generate a random nonce for OAuth
  String _generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return random.abs().toString();
  }
}
