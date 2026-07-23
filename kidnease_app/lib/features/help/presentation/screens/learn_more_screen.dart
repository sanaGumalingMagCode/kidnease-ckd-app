import 'package:flutter/material.dart';
import '../widgets/info_tooltip.dart';

class LearnMoreScreen extends StatelessWidget {
  const LearnMoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Learn About CKD',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A90E2)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A90E2), Color(0xFF50C9C3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Understanding CKD',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Learn how to manage your kidney health',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What is CKD?
            _buildSection(
              icon: Icons.info_outline,
              iconColor: const Color(0xFF4A90E2),
              title: 'What is Chronic Kidney Disease?',
              content: 'Chronic Kidney Disease (CKD) is a condition where your kidneys gradually lose their ability to filter waste and excess fluids from your blood. '
                  'This happens slowly over time, often without symptoms until it becomes advanced.\n\n'
                  'Your kidneys are essential organs that clean your blood, remove waste, control blood pressure, and help make red blood cells.',
            ),

            // Why Diet Matters
            _buildSection(
              icon: Icons.restaurant_rounded,
              iconColor: const Color(0xFFF39C12),
              title: 'Why Diet is Important',
              content: 'What you eat directly affects your kidney health. When you have CKD, your kidneys struggle to process certain nutrients. '
                  'Managing your diet helps:\n\n'
                  '• Slow down kidney damage\n'
                  '• Prevent dangerous complications\n'
                  '• Maintain your quality of life\n'
                  '• Keep you feeling energetic',
            ),

            // Key Nutrients to Monitor
            const Text(
              'Key Nutrients to Monitor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            _buildNutrientCard(
              icon: Icons.water_drop,
              iconColor: const Color(0xFFE74C3C),
              title: 'Sodium (Salt)',
              tooltip: MedicalTerms.sodium,
              description: 'Too much sodium raises blood pressure and causes fluid retention, putting extra strain on your kidneys.',
              tips: [
                'Avoid adding salt to food',
                'Read food labels carefully',
                'Use herbs and spices for flavor',
                'Limit processed and canned foods',
              ],
              highRiskFoods: ['Soy sauce', 'Canned goods', 'Fast food', 'Processed meats'],
              safeFoods: ['Fresh fruits', 'Fresh vegetables', 'Rice', 'Unsalted fish'],
            ),

            _buildNutrientCard(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFF39C12),
              title: 'Potassium',
              tooltip: MedicalTerms.potassium,
              description: 'High potassium levels can cause irregular heartbeat and even cardiac arrest when kidneys can\'t remove excess potassium.',
              tips: [
                'Soak vegetables before cooking',
                'Choose low-potassium fruits',
                'Limit banana and orange intake',
                'Avoid coconut water',
              ],
              highRiskFoods: ['Bananas', 'Oranges', 'Potatoes', 'Tomatoes', 'Beans'],
              safeFoods: ['Apples', 'Grapes', 'Cabbage', 'White rice', 'Cucumber'],
            ),

            _buildNutrientCard(
              icon: Icons.diamond,
              iconColor: const Color(0xFF9B59B6),
              title: 'Phosphorus',
              tooltip: MedicalTerms.phosphorus,
              description: 'Too much phosphorus weakens your bones and damages blood vessels, as damaged kidneys can\'t remove excess phosphorus.',
              tips: [
                'Limit dairy products',
                'Avoid dark-colored sodas',
                'Reduce processed foods',
                'Read labels for phosphate additives',
              ],
              highRiskFoods: ['Milk', 'Cheese', 'Nuts', 'Dark sodas', 'Processed foods'],
              safeFoods: ['Rice milk', 'Egg whites', 'Fresh fish', 'White bread'],
            ),

            _buildNutrientCard(
              icon: Icons.fitness_center,
              iconColor: const Color(0xFF27AE60),
              title: 'Protein',
              tooltip: MedicalTerms.protein,
              description: 'Protein creates waste products that your kidneys must filter. The right amount is important - too much or too little can be harmful.',
              tips: [
                'Eat moderate portions of protein',
                'Choose high-quality protein sources',
                'Balance protein throughout the day',
                'Consult your doctor for your needs',
              ],
              highRiskFoods: ['Red meat', 'Dried beans', 'Organ meats'],
              safeFoods: ['Egg whites', 'Fish', 'Chicken breast', 'Tofu'],
            ),

            const SizedBox(height: 24),

            // Filipino-Friendly Tips
            _buildSection(
              icon: Icons.flag,
              iconColor: const Color(0xFF27AE60),
              title: 'Filipino-Friendly Cooking Tips',
              content: 'You can still enjoy Filipino food while managing CKD! Here are some tips:\n\n'
                  '🍚 Choose white rice over brown rice (lower phosphorus)\n'
                  '🐟 Grill or steam fish instead of frying\n'
                  '🥬 Eat fresh vegetables, not pickled\n'
                  '🍲 Make your own versions with less salt\n'
                  '🥥 Limit coconut milk and coconut water\n'
                  '🧂 Use calamansi, garlic, and ginger for flavor\n'
                  '🍵 Choose tea over dark sodas',
            ),

            // Emergency Warning
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!, width: 2),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red[700], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'When to Seek Help',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Contact your doctor immediately if you experience:\n\n'
                    '• Severe swelling in legs or face\n'
                    '• Difficulty breathing\n'
                    '• Chest pain or irregular heartbeat\n'
                    '• Extreme fatigue or confusion\n'
                    '• Decreased urination',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[900],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information is for educational purposes only. Always consult your healthcare provider for personalized medical advice.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget tooltip,
    required String description,
    required List<String> tips,
    required List<String> highRiskFoods,
    required List<String> safeFoods,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              tooltip,
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Tips
          Text(
            'Management Tips:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✓ ', style: TextStyle(color: iconColor, fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),

          // Food lists
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'High Risk',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...highRiskFoods.map((food) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $food',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Safer Options',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...safeFoods.map((food) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $food',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
