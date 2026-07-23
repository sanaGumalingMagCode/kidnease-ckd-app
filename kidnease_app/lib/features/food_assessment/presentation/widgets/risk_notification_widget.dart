import 'package:flutter/material.dart';
import 'dart:async';

class RiskNotificationWidget extends StatefulWidget {
  final String riskLevel;
  final String foodName;
  final String explanation;
  final List<String> filipinoAlternatives;
  final VoidCallback onDismiss;
  // Macros
  final double sodium;
  final double potassium;
  final double phosphorus;
  final double protein;

  const RiskNotificationWidget({
    Key? key,
    required this.riskLevel,
    required this.foodName,
    required this.explanation,
    required this.filipinoAlternatives,
    required this.onDismiss,
    this.sodium = 0,
    this.potassium = 0,
    this.phosphorus = 0,
    this.protein = 0,
  }) : super(key: key);

  @override
  State<RiskNotificationWidget> createState() => _RiskNotificationWidgetState();
}

class _RiskNotificationWidgetState extends State<RiskNotificationWidget>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _remainingSeconds = 10;

  @override
  void initState() {
    super.initState();

    // Animation setup
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();

    // Auto-dismiss timer (10 seconds)
    _autoDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
            _dismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHighRisk = widget.riskLevel == 'High Risk';
    final backgroundColor = isHighRisk ? Colors.red[50] : Colors.green[50];
    final borderColor = isHighRisk ? Colors.red[700] : Colors.green[700];
    final iconColor = isHighRisk ? Colors.red[700] : Colors.green[700];
    final icon = isHighRisk ? Icons.warning_amber : Icons.check_circle;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor!, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 40, color: iconColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.riskLevel,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                          Text(
                            widget.foodName,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Auto-dismiss countdown
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$_remainingSeconds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Explanation
                      Text(
                        'Explanation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.explanation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),

                      // Estimated Macros
                      const SizedBox(height: 20),
                      Text(
                        'Estimated Nutritional Content',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            _buildMacroRow(
                              icon: Icons.water_drop,
                              color: Colors.blue,
                              label: 'Sodium',
                              value: '${widget.sodium.toStringAsFixed(0)} mg',
                            ),
                            const Divider(height: 16),
                            _buildMacroRow(
                              icon: Icons.local_fire_department,
                              color: Colors.orange,
                              label: 'Potassium',
                              value: '${widget.potassium.toStringAsFixed(0)} mg',
                            ),
                            const Divider(height: 16),
                            _buildMacroRow(
                              icon: Icons.diamond,
                              color: Colors.purple,
                              label: 'Phosphorus',
                              value: '${widget.phosphorus.toStringAsFixed(0)} mg',
                            ),
                            const Divider(height: 16),
                            _buildMacroRow(
                              icon: Icons.fitness_center,
                              color: Colors.green,
                              label: 'Protein',
                              value: '${widget.protein.toStringAsFixed(1)} g',
                            ),
                          ],
                        ),
                      ),

                      // Filipino Alternatives (only for high risk)
                      if (isHighRisk && widget.filipinoAlternatives.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Healthier Filipino Alternatives',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.filipinoAlternatives.map((alternative) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 20,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    alternative,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],

                      // Safe meal affirmation
                      if (!isHighRisk) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.thumb_up, color: Colors.green[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This meal is within your dietary limits. Enjoy!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _dismiss,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Dismiss',
                          style: TextStyle(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _dismiss,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: borderColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Dashboard',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }
}
