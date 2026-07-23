import 'package:flutter/material.dart';

/// A beginner-friendly tooltip that explains medical/technical terms
class InfoTooltip extends StatelessWidget {
  final String title;
  final String explanation;
  final String? example;

  const InfoTooltip({
    Key? key,
    required this.title,
    required this.explanation,
    this.example,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showExplanation(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.help_outline,
          size: 18,
          color: Color(0xFF4A90E2),
        ),
      ),
    );
  }

  void _showExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF4A90E2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              explanation,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            if (example != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        example!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper tooltips for common medical terms
class MedicalTerms {
  static const sodium = InfoTooltip(
    title: 'Sodium',
    explanation: 'Sodium is a mineral found in salt and many foods. For people with kidney disease, too much sodium can cause high blood pressure and fluid buildup.',
    example: 'Found in: Salt, soy sauce, processed foods, fast food, canned goods',
  );

  static const potassium = InfoTooltip(
    title: 'Potassium',
    explanation: 'Potassium helps your nerves and muscles work properly. When kidneys don\'t work well, potassium can build up in your blood and cause dangerous heart problems.',
    example: 'Found in: Bananas, oranges, potatoes, tomatoes, spinach, beans',
  );

  static const phosphorus = InfoTooltip(
    title: 'Phosphorus',
    explanation: 'Phosphorus keeps your bones strong. But when you have kidney disease, too much phosphorus can weaken bones and damage blood vessels.',
    example: 'Found in: Dairy products, nuts, seeds, beans, dark sodas, processed foods',
  );

  static const protein = InfoTooltip(
    title: 'Protein',
    explanation: 'Protein builds and repairs body tissue. Too much protein creates waste that damaged kidneys have difficulty filtering out.',
    example: 'Found in: Meat, fish, eggs, dairy, beans, tofu',
  );

  static const ckd = InfoTooltip(
    title: 'CKD (Chronic Kidney Disease)',
    explanation: 'CKD means your kidneys are gradually losing their ability to filter waste from your blood. Managing your diet helps slow down this damage.',
    example: 'Tracking what you eat helps protect your kidney function and overall health',
  );

  static const kdigo = InfoTooltip(
    title: 'KDIGO Guidelines',
    explanation: 'KDIGO provides international medical guidelines for CKD management. These guidelines help doctors recommend safe nutrient limits based on your kidney function.',
    example: 'Your dietary limits are based on these trusted medical standards',
  );
}
