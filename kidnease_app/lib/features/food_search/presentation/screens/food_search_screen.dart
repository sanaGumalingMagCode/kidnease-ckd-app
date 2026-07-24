import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../food_assessment/data/models/nutritional_data.dart';
import '../../../../shared/providers/providers.dart';
import '../../data/datasources/usda_api_client.dart';
import '../../data/datasources/openfoodfacts_api_client.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  NutritionalData? _searchResult;
  NutritionalData? _baseNutritionalData; // Store base data for portion calculation
  String? _errorMessage;
  String? _dataSource; // Track where data came from
  double _selectedPortion = 100.0; // Default portion size in grams
  final List<double> _portionSizes = [100, 200, 250, 300];
  
  // API clients
  late final USDAApiClient _usdaClient;
  late final OpenFoodFactsApiClient _openFoodFactsClient;

  @override
  void initState() {
    super.initState();
    _usdaClient = USDAApiClient();
    _openFoodFactsClient = OpenFoodFactsApiClient();
  }

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
      _baseNutritionalData = null;
      _dataSource = null;
      _selectedPortion = 100.0;
    });

    try {
      NutritionalData? result;

      // CASCADE SEARCH SYSTEM - No data will clash!
      // Each API is tried in order, first complete result wins
      
      // 1. LOCAL FALLBACK (Highest priority - Filipino dishes, fast food)
      //    Instant results, complete CKD nutrients, culturally relevant
      result = _searchFallbackDatabase(query);
      if (result != null) {
        setState(() {
          _isSearching = false;
          _baseNutritionalData = result;
          _searchResult = result;
          _dataSource = 'Local Database';
        });
        return;
      }

      // 2. USDA API (Second priority - verified government data)
      //    400K+ foods, no rate limits, complete CKD nutrients
      result = await _usdaClient.searchFood(query);
      if (result != null) {
        setState(() {
          _isSearching = false;
          _baseNutritionalData = result;
          _searchResult = result;
          _dataSource = 'USDA FoodData Central';
        });
        return;
      }

      // 3. OPEN FOOD FACTS API (Third priority - global packaged products)
      //    2M+ foods, no rate limits, good for Philippine products
      result = await _openFoodFactsClient.searchFood(query);
      if (result != null) {
        setState(() {
          _isSearching = false;
          _baseNutritionalData = result;
          _searchResult = result;
          _dataSource = 'Open Food Facts';
        });
        return;
      }

      // 4. FATSECRET API (Backup - rate limited but good coverage)
      //    1M+ foods, complete nutrients
      final fatSecretClient = ref.read(fatSecretApiClientProvider);
      result = await fatSecretClient.searchProduct(query);
      if (result != null) {
        setState(() {
          _isSearching = false;
          _baseNutritionalData = result;
          _searchResult = result;
          _dataSource = 'FatSecret';
        });
        return;
      }

      // 5. NOT FOUND in any database
      setState(() {
        _isSearching = false;
        _errorMessage = 'No food found with that name. Try these:\n\n'
            'Common Foods:\n• Banana  • White Rice  • Brown Rice\n• Chicken  • Milk  • Wheat Bread\n\n'
            'Filipino Dishes:\n• Adobo  • Sinigang  • Kare Kare\n• Leche Flan  • Tinola  • Lumpia\n\n'
            'Fast Food:\n• Chickenjoy  • Yumburger  • Big Mac\n• KFC Chicken  • Mang Inasal  • Pizza';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching food: ${e.toString()}';
      });
    }
  }

  void _updatePortionSize(double newPortion) {
    if (_baseNutritionalData == null) return;

    final base = _baseNutritionalData!;
    final ratio = newPortion / 100.0;

    setState(() {
      _selectedPortion = newPortion;
      _searchResult = NutritionalData(
        productName: '${base.productName}',
        servingSize: '${newPortion.toInt()}g',
        sodium: base.sodium * ratio,
        potassium: base.potassium * ratio,
        phosphorus: base.phosphorus * ratio,
        protein: base.protein * ratio,
      );
    });
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
        servingSize: '100g',
        sodium: 1.3,
        potassium: 35.0,
        phosphorus: 27.0,
        protein: 2.7,
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
        servingSize: '100g',
        sodium: 588.0,
        potassium: 104.0,
        phosphorus: 96.0,
        protein: 9.2,
      ),
      'white bread': NutritionalData(
        productName: 'White Bread',
        servingSize: '100g',
        sodium: 588.0,
        potassium: 104.0,
        phosphorus: 96.0,
        protein: 9.2,
      ),
      'wheat bread': NutritionalData(
        productName: 'Whole Wheat Bread',
        servingSize: '100g',
        sodium: 400.0,
        potassium: 220.0,
        phosphorus: 180.0,
        protein: 12.0,
      ),
      'whole wheat bread': NutritionalData(
        productName: 'Whole Wheat Bread',
        servingSize: '100g',
        sodium: 400.0,
        potassium: 220.0,
        phosphorus: 180.0,
        protein: 12.0,
      ),
      'brown bread': NutritionalData(
        productName: 'Brown Bread',
        servingSize: '100g',
        sodium: 480.0,
        potassium: 200.0,
        phosphorus: 170.0,
        protein: 11.0,
      ),
      'multigrain bread': NutritionalData(
        productName: 'Multigrain Bread',
        servingSize: '100g',
        sodium: 420.0,
        potassium: 240.0,
        phosphorus: 190.0,
        protein: 13.0,
      ),
      'rye bread': NutritionalData(
        productName: 'Rye Bread',
        servingSize: '100g',
        sodium: 660.0,
        potassium: 180.0,
        phosphorus: 125.0,
        protein: 8.5,
      ),
      'sourdough bread': NutritionalData(
        productName: 'Sourdough Bread',
        servingSize: '100g',
        sodium: 580.0,
        potassium: 115.0,
        phosphorus: 92.0,
        protein: 9.0,
      ),
      'pandesal': NutritionalData(
        productName: 'Pandesal (Filipino Bread Roll)',
        servingSize: '100g',
        sodium: 520.0,
        potassium: 95.0,
        phosphorus: 88.0,
        protein: 8.5,
      ),
      'rice': NutritionalData(
        productName: 'White Rice (cooked)',
        servingSize: '100g',
        sodium: 1.3,
        potassium: 35.0,
        phosphorus: 27.0,
        protein: 2.7,
      ),
      'white rice': NutritionalData(
        productName: 'White Rice (cooked)',
        servingSize: '100g',
        sodium: 1.3,
        potassium: 35.0,
        phosphorus: 27.0,
        protein: 2.7,
      ),
      'brown rice': NutritionalData(
        productName: 'Brown Rice (cooked)',
        servingSize: '100g',
        sodium: 5.0,
        potassium: 86.0, // Higher potassium
        phosphorus: 83.0, // Much higher phosphorus
        protein: 2.6,
      ),
      'jasmine rice': NutritionalData(
        productName: 'Jasmine Rice (cooked)',
        servingSize: '100g',
        sodium: 1.0,
        potassium: 38.0,
        phosphorus: 30.0,
        protein: 2.8,
      ),
      'basmati rice': NutritionalData(
        productName: 'Basmati Rice (cooked)',
        servingSize: '100g',
        sodium: 2.0,
        potassium: 40.0,
        phosphorus: 32.0,
        protein: 3.0,
      ),
      'red rice': NutritionalData(
        productName: 'Red Rice (cooked)',
        servingSize: '100g',
        sodium: 4.0,
        potassium: 95.0, // High potassium
        phosphorus: 90.0, // High phosphorus
        protein: 3.5,
      ),
      'black rice': NutritionalData(
        productName: 'Black Rice (cooked)',
        servingSize: '100g',
        sodium: 3.0,
        potassium: 100.0, // High potassium
        phosphorus: 95.0, // High phosphorus
        protein: 4.0,
      ),
      'fried rice': NutritionalData(
        productName: 'Fried Rice',
        servingSize: '100g',
        sodium: 380.0, // Much higher from soy sauce
        potassium: 80.0,
        phosphorus: 60.0,
        protein: 4.5,
      ),
      'glutinous rice': NutritionalData(
        productName: 'Glutinous Rice / Sticky Rice (cooked)',
        servingSize: '100g',
        sodium: 2.0,
        potassium: 25.0,
        phosphorus: 18.0,
        protein: 2.2,
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
      
      // Fast Food - Jollibee
      'chickenjoy': NutritionalData(
        productName: 'Jollibee Chickenjoy (1 piece)',
        servingSize: '100g',
        sodium: 890.0, // Very high sodium
        potassium: 280.0,
        phosphorus: 250.0,
        protein: 24.0,
      ),
      'jollibee chickenjoy': NutritionalData(
        productName: 'Jollibee Chickenjoy (1 piece)',
        servingSize: '100g',
        sodium: 890.0,
        potassium: 280.0,
        phosphorus: 250.0,
        protein: 24.0,
      ),
      'jolly spaghetti': NutritionalData(
        productName: 'Jollibee Jolly Spaghetti',
        servingSize: '100g',
        sodium: 650.0, // High sodium
        potassium: 220.0,
        phosphorus: 120.0,
        protein: 8.5,
      ),
      'jollibee spaghetti': NutritionalData(
        productName: 'Jollibee Jolly Spaghetti',
        servingSize: '100g',
        sodium: 650.0,
        potassium: 220.0,
        phosphorus: 120.0,
        protein: 8.5,
      ),
      'yumburger': NutritionalData(
        productName: 'Jollibee Yumburger',
        servingSize: '100g',
        sodium: 720.0, // High sodium
        potassium: 180.0,
        phosphorus: 160.0,
        protein: 14.0,
      ),
      'jollibee burger': NutritionalData(
        productName: 'Jollibee Yumburger',
        servingSize: '100g',
        sodium: 720.0,
        potassium: 180.0,
        phosphorus: 160.0,
        protein: 14.0,
      ),
      'jolly hotdog': NutritionalData(
        productName: 'Jollibee Jolly Hotdog',
        servingSize: '100g',
        sodium: 920.0, // Very high sodium
        potassium: 160.0,
        phosphorus: 145.0,
        protein: 12.0,
      ),
      'palabok': NutritionalData(
        productName: 'Jollibee Palabok Fiesta',
        servingSize: '100g',
        sodium: 780.0, // High sodium
        potassium: 200.0,
        phosphorus: 180.0,
        protein: 10.5,
      ),
      'jollibee palabok': NutritionalData(
        productName: 'Jollibee Palabok Fiesta',
        servingSize: '100g',
        sodium: 780.0,
        potassium: 200.0,
        phosphorus: 180.0,
        protein: 10.5,
      ),
      'peach mango pie': NutritionalData(
        productName: 'Jollibee Peach Mango Pie',
        servingSize: '100g',
        sodium: 240.0,
        potassium: 150.0,
        phosphorus: 65.0,
        protein: 3.2,
      ),
      'jollibee pie': NutritionalData(
        productName: 'Jollibee Peach Mango Pie',
        servingSize: '100g',
        sodium: 240.0,
        potassium: 150.0,
        phosphorus: 65.0,
        protein: 3.2,
      ),
      
      // Fast Food - McDonald's
      'big mac': NutritionalData(
        productName: 'McDonald\'s Big Mac',
        servingSize: '100g',
        sodium: 460.0, // High sodium
        potassium: 140.0,
        phosphorus: 130.0,
        protein: 12.5,
      ),
      'mcdonalds burger': NutritionalData(
        productName: 'McDonald\'s Big Mac',
        servingSize: '100g',
        sodium: 460.0,
        potassium: 140.0,
        phosphorus: 130.0,
        protein: 12.5,
      ),
      'chicken mcdo': NutritionalData(
        productName: 'McDonald\'s Fried Chicken',
        servingSize: '100g',
        sodium: 820.0, // High sodium
        potassium: 260.0,
        phosphorus: 240.0,
        protein: 23.0,
      ),
      'mcnuggets': NutritionalData(
        productName: 'McDonald\'s Chicken McNuggets',
        servingSize: '100g',
        sodium: 680.0,
        potassium: 180.0,
        phosphorus: 200.0,
        protein: 16.5,
      ),
      'chicken nuggets': NutritionalData(
        productName: 'McDonald\'s Chicken McNuggets',
        servingSize: '100g',
        sodium: 680.0,
        potassium: 180.0,
        phosphorus: 200.0,
        protein: 16.5,
      ),
      'french fries': NutritionalData(
        productName: 'French Fries (Fast Food)',
        servingSize: '100g',
        sodium: 210.0,
        potassium: 450.0, // High potassium!
        phosphorus: 120.0,
        protein: 3.4,
      ),
      'fries': NutritionalData(
        productName: 'French Fries (Fast Food)',
        servingSize: '100g',
        sodium: 210.0,
        potassium: 450.0, // High potassium!
        phosphorus: 120.0,
        protein: 3.4,
      ),
      'mcflurry': NutritionalData(
        productName: 'McDonald\'s McFlurry',
        servingSize: '100g',
        sodium: 95.0,
        potassium: 180.0,
        phosphorus: 140.0, // High from milk
        protein: 5.5,
      ),
      
      // Fast Food - KFC
      'kfc chicken': NutritionalData(
        productName: 'KFC Fried Chicken',
        servingSize: '100g',
        sodium: 850.0, // Very high sodium
        potassium: 270.0,
        phosphorus: 260.0,
        protein: 25.0,
      ),
      'kfc': NutritionalData(
        productName: 'KFC Fried Chicken',
        servingSize: '100g',
        sodium: 850.0,
        potassium: 270.0,
        phosphorus: 260.0,
        protein: 25.0,
      ),
      'zinger': NutritionalData(
        productName: 'KFC Zinger Burger',
        servingSize: '100g',
        sodium: 740.0,
        potassium: 190.0,
        phosphorus: 170.0,
        protein: 13.5,
      ),
      'kfc zinger': NutritionalData(
        productName: 'KFC Zinger Burger',
        servingSize: '100g',
        sodium: 740.0,
        potassium: 190.0,
        phosphorus: 170.0,
        protein: 13.5,
      ),
      'mashed potato': NutritionalData(
        productName: 'KFC Mashed Potato with Gravy',
        servingSize: '100g',
        sodium: 420.0, // High sodium from gravy
        potassium: 320.0, // High from potato
        phosphorus: 65.0,
        protein: 2.8,
      ),
      'coleslaw': NutritionalData(
        productName: 'KFC Coleslaw',
        servingSize: '100g',
        sodium: 240.0,
        potassium: 180.0,
        phosphorus: 45.0,
        protein: 1.5,
      ),
      
      // Fast Food - Chowking
      'chowking': NutritionalData(
        productName: 'Chowking Pork Chao Fan',
        servingSize: '100g',
        sodium: 680.0, // High sodium
        potassium: 190.0,
        phosphorus: 140.0,
        protein: 9.5,
      ),
      'chao fan': NutritionalData(
        productName: 'Chowking Pork Chao Fan',
        servingSize: '100g',
        sodium: 680.0,
        potassium: 190.0,
        phosphorus: 140.0,
        protein: 9.5,
      ),
      'wonton soup': NutritionalData(
        productName: 'Chowking Wonton Soup',
        servingSize: '100g',
        sodium: 720.0, // Very high sodium
        potassium: 150.0,
        phosphorus: 95.0,
        protein: 7.5,
      ),
      'siomai': NutritionalData(
        productName: 'Chowking Pork Siomai',
        servingSize: '100g',
        sodium: 620.0,
        potassium: 170.0,
        phosphorus: 160.0,
        protein: 12.0,
      ),
      'chowking siomai': NutritionalData(
        productName: 'Chowking Pork Siomai',
        servingSize: '100g',
        sodium: 620.0,
        potassium: 170.0,
        phosphorus: 160.0,
        protein: 12.0,
      ),
      'lauriat': NutritionalData(
        productName: 'Chowking Lauriat (Mixed Meal)',
        servingSize: '100g',
        sodium: 580.0,
        potassium: 210.0,
        phosphorus: 130.0,
        protein: 11.0,
      ),
      
      // Fast Food - Mang Inasal
      'mang inasal': NutritionalData(
        productName: 'Mang Inasal Chicken Inasal',
        servingSize: '100g',
        sodium: 750.0, // High sodium
        potassium: 310.0,
        phosphorus: 230.0,
        protein: 26.0,
      ),
      'chicken inasal': NutritionalData(
        productName: 'Mang Inasal Chicken Inasal',
        servingSize: '100g',
        sodium: 750.0,
        potassium: 310.0,
        phosphorus: 230.0,
        protein: 26.0,
      ),
      'inasal': NutritionalData(
        productName: 'Mang Inasal Chicken Inasal',
        servingSize: '100g',
        sodium: 750.0,
        potassium: 310.0,
        phosphorus: 230.0,
        protein: 26.0,
      ),
      'pork bbq': NutritionalData(
        productName: 'Mang Inasal Pork BBQ',
        servingSize: '100g',
        sodium: 820.0, // Very high sodium
        potassium: 350.0,
        phosphorus: 240.0,
        protein: 24.0,
      ),
      
      // Fast Food - Greenwich
      'greenwich': NutritionalData(
        productName: 'Greenwich Lasagna Supreme',
        servingSize: '100g',
        sodium: 590.0,
        potassium: 210.0,
        phosphorus: 180.0, // High from cheese
        protein: 11.5,
      ),
      'lasagna': NutritionalData(
        productName: 'Greenwich Lasagna Supreme',
        servingSize: '100g',
        sodium: 590.0,
        potassium: 210.0,
        phosphorus: 180.0,
        protein: 11.5,
      ),
      'pizza': NutritionalData(
        productName: 'Pizza (Cheese)',
        servingSize: '100g',
        sodium: 640.0, // High sodium
        potassium: 170.0,
        phosphorus: 200.0, // High from cheese
        protein: 12.0,
      ),
      'greenwich pizza': NutritionalData(
        productName: 'Greenwich Pizza (Cheese)',
        servingSize: '100g',
        sodium: 640.0,
        potassium: 170.0,
        phosphorus: 200.0,
        protein: 12.0,
      ),
      
      // Additional Common Fast Foods
      'burger': NutritionalData(
        productName: 'Burger (Generic Fast Food)',
        servingSize: '100g',
        sodium: 520.0,
        potassium: 160.0,
        phosphorus: 140.0,
        protein: 13.0,
      ),
      'cheeseburger': NutritionalData(
        productName: 'Cheeseburger (Fast Food)',
        servingSize: '100g',
        sodium: 680.0, // Higher sodium with cheese
        potassium: 170.0,
        phosphorus: 180.0, // Higher with cheese
        protein: 14.5,
      ),
      'hotdog': NutritionalData(
        productName: 'Hotdog (Fast Food)',
        servingSize: '100g',
        sodium: 810.0, // Very high sodium
        potassium: 150.0,
        phosphorus: 130.0,
        protein: 11.5,
      ),
      'hot dog': NutritionalData(
        productName: 'Hotdog (Fast Food)',
        servingSize: '100g',
        sodium: 810.0,
        potassium: 150.0,
        phosphorus: 130.0,
        protein: 11.5,
      ),
      'onion rings': NutritionalData(
        productName: 'Onion Rings (Fast Food)',
        servingSize: '100g',
        sodium: 380.0,
        potassium: 160.0,
        phosphorus: 90.0,
        protein: 4.2,
      ),
      'sundae': NutritionalData(
        productName: 'Ice Cream Sundae (Fast Food)',
        servingSize: '100g',
        sodium: 75.0,
        potassium: 160.0,
        phosphorus: 110.0, // High from milk
        protein: 4.5,
      ),
      'soft drink': NutritionalData(
        productName: 'Soft Drink / Soda',
        servingSize: '100g',
        sodium: 8.0,
        potassium: 2.0,
        phosphorus: 12.0, // Contains phosphoric acid
        protein: 0.0,
      ),
      'soda': NutritionalData(
        productName: 'Soft Drink / Soda',
        servingSize: '100g',
        sodium: 8.0,
        potassium: 2.0,
        phosphorus: 12.0,
        protein: 0.0,
      ),
      'coke': NutritionalData(
        productName: 'Coca-Cola / Soft Drink',
        servingSize: '100g',
        sodium: 8.0,
        potassium: 2.0,
        phosphorus: 12.0, // Contains phosphoric acid
        protein: 0.0,
      ),
      'iced tea': NutritionalData(
        productName: 'Iced Tea (Sweetened)',
        servingSize: '100g',
        sodium: 6.0,
        potassium: 15.0,
        phosphorus: 3.0,
        protein: 0.1,
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
              
              // Data source indicator
              if (_dataSource != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getDataSourceColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getDataSourceColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDataSourceIcon(),
                          size: 16,
                          color: _getDataSourceColor(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Source: $_dataSource',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDataSourceColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDataSourceColor() {
    switch (_dataSource) {
      case 'Local Database':
        return const Color(0xFF4CAF50); // Green
      case 'USDA FoodData Central':
        return const Color(0xFF2196F3); // Blue
      case 'Open Food Facts':
        return const Color(0xFFFF9800); // Orange
      case 'FatSecret':
        return const Color(0xFF9C27B0); // Purple
      default:
        return Colors.grey;
    }
  }

  IconData _getDataSourceIcon() {
    switch (_dataSource) {
      case 'Local Database':
        return Icons.home;
      case 'USDA FoodData Central':
        return Icons.verified;
      case 'Open Food Facts':
        return Icons.public;
      case 'FatSecret':
        return Icons.cloud;
      default:
        return Icons.info;
    }
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

          // Portion Size Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.scale,
                      size: 20,
                      color: Color(0xFF4A90E2),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Portion Size:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<double>(
                        value: _selectedPortion,
                        underline: const SizedBox(),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        items: _portionSizes.map((size) {
                          return DropdownMenuItem<double>(
                            value: size,
                            child: Text(
                              '${size.toInt()}g',
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            _updatePortionSize(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select portion size to adjust nutritional values',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
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
