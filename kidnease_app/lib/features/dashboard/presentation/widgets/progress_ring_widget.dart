import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/utils/logger.dart';

class ProgressRingWidget extends ConsumerWidget {
  final String userId;
  final DietaryProfile profile;

  const ProgressRingWidget({
    Key? key,
    required this.userId,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreRepo = ref.watch(firestoreRepositoryProvider);

    return FutureBuilder<Map<String, double>>(
      future: firestoreRepo.getDailyNutrientTotals(userId, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors gracefully
        if (snapshot.hasError) {
          logger.warning('Error loading daily totals: ${snapshot.error}');
          // Show default values when there's an error
          return _buildProgressRings({
            'sodium': 0.0,
            'potassium': 0.0,
            'phosphorus': 0.0,
            'protein': 0.0,
          });
        }

        final totals = snapshot.data ?? {
          'sodium': 0.0,
          'potassium': 0.0,
          'phosphorus': 0.0,
          'protein': 0.0,
        };

        return _buildProgressRings(totals);
      },
    );
  }

  Widget _buildProgressRings(Map<String, double> totals) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressRing(
                  'Sodium',
                  totals['sodium']!,
                  profile.dailySodiumLimit,
                  'mg',
                  Colors.red,
                ),
                _buildProgressRing(
                  'Potassium',
                  totals['potassium']!,
                  profile.dailyPotassiumLimit,
                  'mg',
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressRing(
                  'Phosphorus',
                  totals['phosphorus']!,
                  profile.dailyPhosphorusLimit,
                  'mg',
                  Colors.blue,
                ),
                _buildProgressRing(
                  'Protein',
                  totals['protein']!,
                  profile.dailyProteinLimit,
                  'g',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRing(
    String label,
    double current,
    double limit,
    String unit,
    Color color,
  ) {
    final percentage = (current / limit).clamp(0.0, 1.0);
    final isOverLimit = current > limit;

    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                ),
              ),
              // Progress circle
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOverLimit ? Colors.red : color,
                  ),
                ),
              ),
              // Percentage text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isOverLimit ? Colors.red : color,
                    ),
                  ),
                  if (isOverLimit)
                    const Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${current.toInt()} / ${limit.toInt()} $unit',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
