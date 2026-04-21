import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../../food_assessment/data/repositories/firestore_repository.dart';
import '../../../../shared/providers/providers.dart';

class NutrientChartWidget extends ConsumerStatefulWidget {
  final String userId;
  final DietaryProfile profile;

  const NutrientChartWidget({
    Key? key,
    required this.userId,
    required this.profile,
  }) : super(key: key);

  @override
  ConsumerState<NutrientChartWidget> createState() => _NutrientChartWidgetState();
}

class _NutrientChartWidgetState extends ConsumerState<NutrientChartWidget> {
  int _selectedDays = 7; // Default to 7 days

  @override
  Widget build(BuildContext context) {
    final firestoreRepo = ref.watch(firestoreRepositoryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimeRangeButton('7D', 7),
                  _buildTimeRangeButton('14D', 14),
                  _buildTimeRangeButton('30D', 30),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Charts
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchNutrientHistory(firestoreRepo),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading data: ${snapshot.error}'),
                );
              }

              final data = snapshot.data ?? [];

              if (data.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start scanning food to see your trends',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  _buildChart(
                    'Sodium (mg)',
                    data,
                    'sodium',
                    widget.profile.dailySodiumLimit,
                    Colors.red,
                  ),
                  const SizedBox(height: 24),
                  _buildChart(
                    'Potassium (mg)',
                    data,
                    'potassium',
                    widget.profile.dailyPotassiumLimit,
                    Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  _buildChart(
                    'Phosphorus (mg)',
                    data,
                    'phosphorus',
                    widget.profile.dailyPhosphorusLimit,
                    Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  _buildChart(
                    'Protein (g)',
                    data,
                    'protein',
                    widget.profile.dailyProteinLimit,
                    Colors.green,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(String label, int days) {
    final isSelected = _selectedDays == days;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedDays = days;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        elevation: isSelected ? 2 : 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildChart(
    String title,
    List<Map<String, dynamic>> data,
    String nutrientKey,
    double limit,
    Color color,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final value = data[i][nutrientKey] as double? ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: limit / 4,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            final date = data[index]['date'] as DateTime;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  lineBarsData: [
                    // Actual consumption line
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      // Limit threshold line
                      HorizontalLine(
                        y: limit,
                        color: Colors.red,
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          labelResolver: (line) => 'Limit',
                        ),
                      ),
                    ],
                  ),
                  minY: 0,
                  maxY: limit * 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchNutrientHistory(
    FirestoreRepository firestoreRepo,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: _selectedDays));

    final history = <Map<String, dynamic>>[];

    for (int i = 0; i < _selectedDays; i++) {
      final date = startDate.add(Duration(days: i));
      final totals = await firestoreRepo.getDailyNutrientTotals(
        widget.userId,
        date,
      );

      history.add({
        'date': date,
        'sodium': totals['sodium'] ?? 0.0,
        'potassium': totals['potassium'] ?? 0.0,
        'phosphorus': totals['phosphorus'] ?? 0.0,
        'protein': totals['protein'] ?? 0.0,
      });
    }

    return history;
  }
}
