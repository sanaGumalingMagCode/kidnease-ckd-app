import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../help/presentation/widgets/info_tooltip.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with helpful message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF4A90E2),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tap the help icons to learn what each nutrient means',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Progress rings
        Row(
          children: [
            _buildProgressRing(
              'Sodium',
              totals['sodium']!,
              profile.dailySodiumLimit,
              'mg',
              const Color(0xFFE74C3C),
            ),
            const SizedBox(width: 12),
            _buildProgressRing(
              'Potassium',
              totals['potassium']!,
              profile.dailyPotassiumLimit,
              'mg',
              const Color(0xFFF39C12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildProgressRing(
              'Phosphorus',
              totals['phosphorus']!,
              profile.dailyPhosphorusLimit,
              'mg',
              const Color(0xFF3498DB),
            ),
            const SizedBox(width: 12),
            _buildProgressRing(
              'Protein',
              totals['protein']!,
              profile.dailyProteinLimit,
              'g',
              const Color(0xFF27AE60),
            ),
          ],
        ),
      ],
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
    final isNearLimit = percentage >= 0.8 && !isOverLimit;

    // Determine status color
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOverLimit) {
      statusColor = Colors.red;
      statusText = 'Over limit';
      statusIcon = Icons.warning_rounded;
    } else if (isNearLimit) {
      statusColor = Colors.orange;
      statusText = 'Near limit';
      statusIcon = Icons.info_outline;
    } else {
      statusColor = color;
      statusText = 'Healthy';
      statusIcon = Icons.check_circle_outline;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Label with info tooltip
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(width: 6),
                _getTooltipForNutrient(label),
              ],
            ),
            const SizedBox(height: 12),

            // Progress ring
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: percentage,
                      strokeWidth: 8,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  // Percentage text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Values
            Text(
              '${current.toInt()} / ${limit.toInt()} $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Remaining: ${(limit - current).toInt()} $unit',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTooltipForNutrient(String label) {
    switch (label.toLowerCase()) {
      case 'sodium':
        return MedicalTerms.sodium;
      case 'potassium':
        return MedicalTerms.potassium;
      case 'phosphorus':
        return MedicalTerms.phosphorus;
      case 'protein':
        return MedicalTerms.protein;
      default:
        return const SizedBox.shrink();
    }
  }
}
