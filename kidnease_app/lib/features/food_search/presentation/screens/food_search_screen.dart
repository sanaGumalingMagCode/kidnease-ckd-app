import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../shared/providers/providers.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  NutritionalData? _searchResult;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFood() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a food name';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResult = null;
    });

    try {
      // Try FatSecret API first
      final fatSecretClient = ref.read(fatSecretApiClientProvider);
      var result = await fatSecretClient.searchProduct(query);

      // If FatSecret returns null, use fallback database
      if (result == null) {
        result = _searchFallbackDatabase(query);
      }

      setState(() {
        _isSearching = false;
        if (result != null) {
          _searchResult = result;
        } else {
          _errorMessage = 'No food found with that name. Try these:\n\n'
              'Common Foods:\n• Banana  • White Rice  • Chicken\n• Milk  • Egg  • Bread\n\n'
              'Filipino Dishes:\n• Adobo  • Sinigang  • Kare Kare\n• Leche Flan  • Tinola  • Lumpia';
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching food: ${e.toString()}';
      });
    }
  }

  // Fallback database for common foods (CKD-relevant nutritional data)
  NutritionalData? _searchFallbackDatabase(String query) {
    final foods = {
      // Common foods
      'banana': NutritionalData(
        productName: 'Banana (medium, 118g)',
        servingSize: '1 medium banana (118g)',
        sodium: 1.2,
        potassium: 422.0,
        phosphorus: 26.0,
        protein: 1.3,
      ),
      'white rice': NutritionalData(
        productName: 'White Rice (cooked)',
        servingSize: '1 cup (158g)',
        sodium: 2.0,
        potassium: 55.0,
        phosphorus: 43.0,
        protein: 4.3,
      ),
      'rice': NutritionalData(
        productName: 'White Rice (cooked)',
        servingSize: '1 cup (158g)',
        sodium: 2.0,
        potassium: 55.0,
        phosphorus: 43.0,
        protein: 4.3,
      ),
      'chicken': NutritionalData(
        productName: 'Chicken Breast (cooked)',
        servingSize: '100g',
        sodium: 74.0,
        potassium: 256.0,
        phosphorus: 228.0,
        protein: 31.0,
      ),
      'chicken breast': NutritionalData(
        productName: 'Chicken Breast (cooked)',
        servingSize: '100g',
        sodium: 74.0,
        potassium: 256.0,
        phosphorus: 228.0,
        protein: 31.0,
      ),
      'milk': NutritionalData(
        productName: 'Whole Milk',
        servingSize: '1 cup (244g)',
        sodium: 105.0,
        potassium: 322.0,
        phosphorus: 205.0,
        protein: 7.9,
      ),
      'egg': NutritionalData(
        productName: 'Egg (large)',
        servingSize: '1 large egg (50g)',
        sodium: 71.0,
        potassium: 69.0,
        phosphorus: 99.0,
        protein: 6.3,
      ),
      'bread': NutritionalData(
        productName: 'White Bread',
        servingSize: '1 slice (25g)',
        sodium: 147.0,
        potassium: 26.0,
        phosphorus: 24.0,
        protein: 2.3,
      ),
      'apple': NutritionalData(
        productName: 'Apple (medium)',
        servingSize: '1 medium apple (182g)',
        sodium: 1.8,
        potassium: 195.0,
        phosphorus: 20.0,
        protein: 0.5,
      ),
      'orange': NutritionalData(
        productName: 'Orange (medium)',
        servingSize: '1 medium orange (131g)',
        sodium: 0.0,
        potassium: 237.0,
        phosphorus: 18.0,
        protein: 1.2,
      ),
      'potato': NutritionalData(
        productName: 'Potato (boiled)',
        servingSize: '1 medium (173g)',
        sodium: 10.0,
        potassium: 544.0,
        phosphorus: 84.0,
        protein: 3.1,
      ),
      'fish': NutritionalData(
        productName: 'White Fish (cooked)',
        servingSize: '100g',
        sodium: 54.0,
        potassium: 390.0,
        phosphorus: 250.0,
        protein: 22.0,
      ),
      'pork': NutritionalData(
        productName: 'Pork (lean, cooked)',
        servingSize: '100g',
        sodium: 62.0,
        potassium: 423.0,
        phosphorus: 246.0,
        protein: 27.0,
      ),
      'beef': NutritionalData(
        productName: 'Beef (lean, cooked)',
        servingSize: '100g',
        sodium: 72.0,
        potassium: 370.0,
        phosphorus: 230.0,
        protein: 26.0,
      ),
      
      // Filipino Dishes
      'adobo': NutritionalData(
        productName: 'Chicken Adobo (Filipino)',
        servingSize: '1 cup (240g)',
        sodium: 800.0, // High sodium from soy sauce
        potassium: 350.0,
        phosphorus: 200.0,
        protein: 25.0,
      ),
      'chicken adobo': NutritionalData(
        productName: 'Chicken Adobo (Filipino)',
        servingSize: '1 cup (240g)',
        sodium: 800.0,
        potassium: 350.0,
        phosphorus: 200.0,
        protein: 25.0,
      ),
      'sinigang': NutritionalData(
        productName: 'Sinigang (Filipino Soup)',
        servingSize: '1 bowl (300g)',
        sodium: 650.0,
        potassium: 450.0,
        phosphorus: 150.0,
        protein: 18.0,
      ),
      'kare kare': NutritionalData(
        productName: 'Kare-Kare (Filipino Peanut Stew)',
        servingSize: '1 cup (250g)',
        sodium: 520.0,
        potassium: 480.0, // High from peanuts and vegetables
        phosphorus: 200.0, // High from peanuts
        protein: 20.0,
      ),
      'kare-kare': NutritionalData(
        productName: 'Kare-Kare (Filipino Peanut Stew)',
        servingSize: '1 cup (250g)',
        sodium: 520.0,
        potassium: 480.0,
        phosphorus: 200.0,
        protein: 20.0,
      ),
      'leche flan': NutritionalData(
        productName: 'Leche Flan (Filipino Custard)',
        servingSize: '1 slice (80g)',
        sodium: 85.0,
        potassium: 150.0,
        phosphorus: 140.0, // High from eggs and milk
        protein: 6.5,
      ),
      'lechon': NutritionalData(
        productName: 'Lechon (Roasted Pig)',
        servingSize: '100g',
        sodium: 750.0, // High sodium
        potassium: 320.0,
        phosphorus: 280.0, // High from meat
        protein: 28.0,
      ),
      'lumpia': NutritionalData(
        productName: 'Lumpia (Filipino Spring Roll)',
        servingSize: '2 pieces (100g)',
        sodium: 450.0,
        potassium: 180.0,
        phosphorus: 120.0,
        protein: 8.0,
      ),
      'pancit': NutritionalData(
        productName: 'Pancit (Filipino Noodles)',
        servingSize: '1 cup (200g)',
        sodium: 680.0, // High from soy sauce
        potassium: 220.0,
        phosphorus: 140.0,
        protein: 12.0,
      ),
      'tinola': NutritionalData(
        productName: 'Tinola (Chicken Ginger Soup)',
        servingSize: '1 bowl (300g)',
        sodium: 580.0,
        potassium: 380.0,
        phosphorus: 180.0,
        protein: 22.0,
      ),
      'sisig': NutritionalData(
        productName: 'Sisig (Filipino Sizzling Pork)',
        servingSize: '1 cup (200g)',
        sodium: 920.0, // Very high sodium
        potassium: 350.0,
        phosphorus: 240.0,
        protein: 24.0,
      ),
      'halo halo': NutritionalData(
        productName: 'Halo-Halo (Filipino Dessert)',
        servingSize: '1 serving (300g)',
        sodium: 120.0,
        potassium: 380.0, // High from fruits and beans
        phosphorus: 160.0,
        protein: 6.0,
      ),
      'halo-halo': NutritionalData(
        productName: 'Halo-Halo (Filipino Dessert)',
        servingSize: '1 serving (300g)',
        sodium: 120.0,
        potassium: 380.0,
        phosphorus: 160.0,
        protein: 6.0,
      ),
      'bistek': NutritionalData(
        productName: 'Bistek Tagalog (Filipino Beef Steak)',
        servingSize: '1 serving (200g)',
        sodium: 720.0, // High from soy sauce
        potassium: 420.0,
        phosphorus: 260.0,
        protein: 26.0,
      ),
      'menudo': NutritionalData(
        productName: 'Menudo (Filipino Pork Stew)',
        servingSize: '1 cup (240g)',
        sodium: 650.0,
        potassium: 450.0, // High from tomatoes and potatoes
        phosphorus: 220.0,
        protein: 22.0,
      ),
      'caldereta': NutritionalData(
        productName: 'Caldereta (Filipino Beef Stew)',
        servingSize: '1 cup (240g)',
        sodium: 780.0,
        potassium: 520.0, // High from tomatoes and potatoes
        phosphorus: 240.0,
        protein: 24.0,
      ),
      'paksiw': NutritionalData(
        productName: 'Paksiw na Isda (Fish in Vinegar)',
        servingSize: '1 serving (150g)',
        sodium: 480.0,
        potassium: 410.0,
        phosphorus: 270.0, // High from fish
        protein: 23.0,
      ),
      'nilaga': NutritionalData(
        productName: 'Nilaga (Filipino Beef Soup)',
        servingSize: '1 bowl (300g)',
        sodium: 620.0,
        potassium: 480.0, // High from vegetables
        phosphorus: 200.0,
        protein: 20.0,
      ),
      'dinuguan': NutritionalData(
        productName: 'Dinuguan (Pork Blood Stew)',
        servingSize: '1 cup (240g)',
        sodium: 850.0, // High sodium
        potassium: 320.0,
        phosphorus: 280.0, // Very high from blood and pork
        protein: 18.0,
      ),
      'arroz caldo': NutritionalData(
        productName: 'Arroz Caldo (Filipino Rice Porridge)',
        servingSize: '1 bowl (300g)',
        sodium: 720.0,
        potassium: 280.0,
        phosphorus: 160.0,
        protein: 16.0,
      ),
      'bulalo': NutritionalData(
        productName: 'Bulalo (Beef Marrow Soup)',
        servingSize: '1 bowl (350g)',
        sodium: 680.0,
        potassium: 500.0,
        phosphorus: 320.0, // Very high from bone marrow
        protein: 22.0,
      ),
      'tocino': NutritionalData(
        productName: 'Tocino (Sweet Cured Pork)',
        servingSize: '100g',
        sodium: 920.0, // Very high sodium from curing
        potassium: 320.0,
        phosphorus: 240.0,
        protein: 26.0,
      ),
      'longganisa': NutritionalData(
        productName: 'Longganisa (Filipino Sausage)',
        servingSize: '2 links (100g)',
        sodium: 880.0, // Very high sodium
        potassium: 280.0,
        phosphorus: 220.0,
        protein: 24.0,
      ),
      'turon': NutritionalData(
        productName: 'Turon (Banana Spring Roll)',
        servingSize: '1 piece (80g)',
        sodium: 120.0,
        potassium: 280.0, // High from banana
        phosphorus: 45.0,
        protein: 2.5,
      ),
      'bibingka': NutritionalData(
        productName: 'Bibingka (Rice Cake)',
        servingSize: '1 piece (100g)',
        sodium: 180.0,
        potassium: 140.0,
        phosphorus: 160.0, // High from eggs and coconut milk
        protein: 5.5,
      ),
      'puto': NutritionalData(
        productName: 'Puto (Steamed Rice Cake)',
        servingSize: '2 pieces (60g)',
        sodium: 95.0,
        potassium: 80.0,
        phosphorus: 85.0,
        protein: 3.2,
      ),
      'cassava cake': NutritionalData(
        productName: 'Cassava Cake',
        servingSize: '1 slice (100g)',
        sodium: 110.0,
        potassium: 220.0,
        phosphorus: 125.0,
        protein: 4.0,
      ),
      'ube halaya': NutritionalData(
        productName: 'Ube Halaya (Purple Yam Jam)',
        servingSize: '100g',
        sodium: 65.0,
        potassium: 380.0, // High from ube
        phosphorus: 95.0,
        protein: 2.8,
      ),
    };

    final lowerQuery = query.toLowerCase();

    // Exact match first
    if (foods.containsKey(lowerQuery)) return foods[lowerQuery];

    // Partial match - find first food whose key contains the query or vice versa
    for (final entry in foods.entries) {
      if (entry.key.contains(lowerQuery) || lowerQuery.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Food Search',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A90E2)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF4A90E2),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for Filipino dishes, common foods, and packaged products to see their nutritional information',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Try: "kare kare", "leche flan", "banana"',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF4A90E2),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResult = null;
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to show/hide clear button
                  },
                  onSubmitted: (_) => _searchFood(),
                ),
              ),
              const SizedBox(height: 16),

              // Search button
              ElevatedButton(
                onPressed: _isSearching ? null : _searchFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSearching
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Search',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Search result
              if (_searchResult != null) _buildResultCard(_searchResult!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(NutritionalData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Serving: ${data.servingSize}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nutritional information
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CKD-Important Nutrients',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 16),

                // Sodium
                _buildNutrientRow(
                  icon: Icons.water_drop,
                  color: Colors.blue,
                  label: 'Sodium',
                  value: '${data.sodium.toStringAsFixed(0)} mg',
                ),
                const Divider(height: 24),

                // Potassium
                _buildNutrientRow(
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  label: 'Potassium',
                  value: '${data.potassium.toStringAsFixed(0)} mg',
                ),
                const Divider(height: 24),

                // Phosphorus
                _buildNutrientRow(
                  icon: Icons.diamond,
                  color: Colors.purple,
                  label: 'Phosphorus',
                  value: '${data.phosphorus.toStringAsFixed(0)} mg',
                ),
                const Divider(height: 24),

                // Protein
                _buildNutrientRow(
                  icon: Icons.fitness_center,
                  color: Colors.green,
                  label: 'Protein',
                  value: '${data.protein.toStringAsFixed(1)} g',
                ),
              ],
            ),
          ),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compare these values with your daily limits',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A90E2),
          ),
        ),
      ],
    );
  }
}
