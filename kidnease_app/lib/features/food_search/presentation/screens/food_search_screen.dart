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

  // Selected food and its base data for portion scaling
  NutritionalData? _selectedFood;
  NutritionalData? _baseNutritionalData;

  // List of search results
  List<NutritionalData> _searchResults = [];
  String? _dataSource;
  String? _errorMessage;

  double _selectedPortion = 100.0;
  final List<double> _portionSizes = [100, 200, 250, 300];

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

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<void> _searchFood() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _errorMessage = 'Please enter a food name');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _searchResults = [];
      _selectedFood = null;
      _baseNutritionalData = null;
      _dataSource = null;
      _selectedPortion = 100.0;
    });

    try {
      List<NutritionalData> results = [];

      // 1. Open Food Facts first (2M+ foods)
      print('🔍 Searching Open Food Facts for: "$query"');
      final offResults = await _openFoodFactsClient.searchFoods(query);
      results.addAll(offResults);
      print('✅ Open Food Facts: ${offResults.length} results');

      // 2. USDA next (400K+ foods) — merge, avoiding exact name duplicates
      print('🔍 Searching USDA for: "$query"');
      final usdaResults = await _usdaClient.searchFoods(query);
      print('✅ USDA: ${usdaResults.length} results');

      for (final item in usdaResults) {
        final alreadyHave = results.any(
          (r) => r.productName.toLowerCase() == item.productName.toLowerCase(),
        );
        if (!alreadyHave) results.add(item);
      }

      if (results.isEmpty) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'No food found for "$query".\n\n'
              'Tips:\n'
              '• Use simple terms: "chicken", "rice", "egg"\n'
              '• Try ingredient names: "broccoli", "salmon"\n'
              '• Try brand + product: "coca cola", "lucky me"\n'
              '• Check spelling';
        });
        return;
      }

      // Determine primary source label
      String source = 'USDA FoodData Central';
      if (offResults.isNotEmpty) source = 'Open Food Facts + USDA';
      if (offResults.isEmpty) source = 'USDA FoodData Central';
      if (usdaResults.isEmpty && offResults.isNotEmpty) source = 'Open Food Facts';

      setState(() {
        _isSearching = false;
        _searchResults = results;
        _dataSource = source;
      });
    } catch (e, st) {
      print('⚠️ Error: $e\n$st');
      setState(() {
        _isSearching = false;
        _errorMessage = 'Error searching: ${e.toString()}\n\nCheck your internet connection.';
      });
    }
  }

  void _selectFood(NutritionalData food) {
    setState(() {
      _baseNutritionalData = _normalize100g(food);
      _selectedPortion = 100.0;
      _selectedFood = _baseNutritionalData;
    });
  }

  /// Strip source suffix and keep only per-100g values
  NutritionalData _normalize100g(NutritionalData food) => NutritionalData(
        productName: food.productName
            .replaceAll(' [USDA]', '')
            .replaceAll(' [Open Food Facts]', '')
            .replaceAll(' [OpenFoodFacts]', ''),
        servingSize: '100g',
        sodium: food.sodium,
        potassium: food.potassium,
        phosphorus: food.phosphorus,
        protein: food.protein,
      );

  void _updatePortion(double newPortion) {
    if (_baseNutritionalData == null) return;
    final base = _baseNutritionalData!;
    final ratio = newPortion / 100.0;
    setState(() {
      _selectedPortion = newPortion;
      _selectedFood = NutritionalData(
        productName: base.productName,
        servingSize: '${newPortion.toInt()}g',
        sodium: base.sodium * ratio,
        potassium: base.potassium * ratio,
        phosphorus: base.phosphorus * ratio,
        protein: base.protein * ratio,
      );
    });
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Food Search',
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A90E2)),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _selectedFood != null
                ? _buildFoodDetail()
                : _searchResults.isNotEmpty
                    ? _buildResultsList()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  // ─── Search bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchFood(),
                  decoration: InputDecoration(
                    hintText: 'Search foods, e.g. "chicken", "rice"…',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF4A90E2)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _selectedFood = null;
                                _errorMessage = null;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          if (_dataSource != null && _searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cloud_done_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${_searchResults.length} results from $_dataSource',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Results list ─────────────────────────────────────────────────────────

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, i) {
        final food = _searchResults[i];
        final isOFF = food.productName.contains('[Open Food Facts]') ||
            food.productName.contains('[OpenFoodFacts]');
        final sourceColor = isOFF ? const Color(0xFFE67E22) : const Color(0xFF27AE60);
        final sourceLabel = isOFF ? 'Open Food Facts' : 'USDA';
        final displayName = food.productName
            .replaceAll(' [USDA]', '')
            .replaceAll(' [Open Food Facts]', '')
            .replaceAll(' [OpenFoodFacts]', '');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: InkWell(
            onTap: () => _selectFood(food),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFF4A90E2), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF2C3E50),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _miniNutrient('Na', food.sodium, Colors.blue),
                            const SizedBox(width: 6),
                            _miniNutrient('K', food.potassium, Colors.orange),
                            const SizedBox(width: 6),
                            _miniNutrient('P', food.phosphorus, Colors.purple),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: sourceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sourceLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: sourceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniNutrient(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}mg',
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ─── Food detail ──────────────────────────────────────────────────────────

  Widget _buildFoodDetail() {
    final food = _selectedFood!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back to results button
          TextButton.icon(
            onPressed: () => setState(() => _selectedFood = null),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to results'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4A90E2),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),

          // Food name header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.productName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Serving: ${food.servingSize}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Portion selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.scale, color: Color(0xFF4A90E2), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Portion Size',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const Spacer(),
                    DropdownButton<double>(
                      value: _selectedPortion,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      items: _portionSizes
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.toInt()}g'),
                              ))
                          .toList(),
                      onChanged: (v) { if (v != null) _updatePortion(v); },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Values below are calculated for ${_selectedPortion.toInt()}g',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nutrient card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CKD-Important Nutrients',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 12),
                _nutrientRow(Icons.water_drop, 'Sodium', food.sodium, 'mg', Colors.blue),
                const Divider(height: 20),
                _nutrientRow(Icons.local_fire_department, 'Potassium', food.potassium, 'mg', Colors.orange),
                const Divider(height: 20),
                _nutrientRow(Icons.diamond, 'Phosphorus', food.phosphorus, 'mg', Colors.purple),
                const Divider(height: 20),
                _nutrientRow(Icons.fitness_center, 'Protein', food.protein, 'g', Colors.green),
                const SizedBox(height: 8),
                Text(
                  '* Values per ${_selectedPortion.toInt()}g serving',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Use this food button
          ElevatedButton.icon(
            onPressed: () => _confirmAddFood(food),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Use This Food', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutrientRow(IconData icon, String label, double value, String unit, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF2C3E50))),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A90E2)),
        ),
      ],
    );
  }

  // ─── Empty / error state ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 70, color: Colors.grey[200]),
            const SizedBox(height: 16),
            Text(
              'Search for any food',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try: "chicken", "rice", "banana",\n"fried chicken", "coca cola"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Confirm add ─────────────────────────────────────────────────────────

  void _confirmAddFood(NutritionalData food) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              food.productName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 4),
            Text(
              'Portion: ${food.servingSize}  •  Na: ${food.sodium.toStringAsFixed(0)}mg  •  K: ${food.potassium.toStringAsFixed(0)}mg  •  P: ${food.phosphorus.toStringAsFixed(0)}mg',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, food);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add to Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
