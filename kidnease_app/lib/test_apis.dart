import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Simple API testing screen to verify Gemini and FatSecret APIs
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _geminiStatus = 'Not tested';
  String _fatSecretStatus = 'Not tested';
  bool _testing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Gemini API Key: ${_maskApiKey(dotenv.env['GEMINI_API_KEY'] ?? 'Not set')}'),
                    Text('FatSecret Key: ${_maskApiKey(dotenv.env['FATSECRET_KEY'] ?? 'Not set')}'),
                    Text('FatSecret Secret: ${_maskApiKey(dotenv.env['FATSECRET_SECRET'] ?? 'Not set')}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Gemini API: $_geminiStatus'),
                    const SizedBox(height: 8),
                    Text('FatSecret API: $_fatSecretStatus'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testing ? null : _testApis,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _testing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Testing APIs...'),
                      ],
                    )
                  : const Text('Test APIs'),
            ),
          ],
        ),
      ),
    );
  }

  String _maskApiKey(String key) {
    if (key == 'Not set' || key.isEmpty) return 'Not set';
    if (key.length <= 8) return '***${key.substring(key.length - 4)}';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  Future<void> _testApis() async {
    setState(() {
      _testing = true;
      _geminiStatus = 'Testing...';
      _fatSecretStatus = 'Testing...';
    });

    // Test Gemini API
    await _testGemini();

    // Test FatSecret API
    await _testFatSecret();

    setState(() {
      _testing = false;
    });
  }

  Future<void> _testGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _geminiStatus = '❌ API key not configured';
        });
        return;
      }

      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Say "API is working" if you can read this.'}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        setState(() {
          _geminiStatus = '✅ Working! Response: ${text.substring(0, text.length > 50 ? 50 : text.length)}...';
        });
      } else {
        setState(() {
          _geminiStatus = '❌ Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _geminiStatus = '❌ Error: $e';
      });
    }
  }

  Future<void> _testFatSecret() async {
    try {
      final consumerKey = dotenv.env['FATSECRET_KEY'];
      final consumerSecret = dotenv.env['FATSECRET_SECRET'];
      
      if (consumerKey == null || consumerKey.isEmpty || 
          consumerSecret == null || consumerSecret.isEmpty) {
        setState(() {
          _fatSecretStatus = '❌ API credentials not configured';
        });
        return;
      }

      // For simplicity, we'll just check if we can make a request
      // The actual OAuth signing is complex, so we'll test with basic auth
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();
      final nonce = timestamp.hashCode.abs().toString();
      
      final params = {
        'method': 'foods.search',
        'search_expression': 'apple',
        'format': 'json',
        'oauth_consumer_key': consumerKey,
        'oauth_signature_method': 'HMAC-SHA1',
        'oauth_timestamp': timestamp,
        'oauth_nonce': nonce,
        'oauth_version': '1.0',
      };

      // Note: This is a simplified test - the actual signature generation is in the client
      final uri = Uri.parse('https://platform.fatsecret.com/rest/server.api').replace(
        queryParameters: params,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _fatSecretStatus = '✅ Working! (OAuth signature needed for full access)';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _fatSecretStatus = '⚠️ Authentication issue (OAuth signature needed)';
        });
      } else {
        setState(() {
          _fatSecretStatus = '❌ Error ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _fatSecretStatus = '❌ Error: $e';
      });
    }
  }
}
