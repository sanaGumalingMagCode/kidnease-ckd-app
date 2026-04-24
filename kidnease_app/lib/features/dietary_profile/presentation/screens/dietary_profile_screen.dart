import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/kdigo_limits.dart';
import '../../../../shared/providers/providers.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';

class DietaryProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final DietaryProfile? existingProfile;

  const DietaryProfileScreen({
    Key? key,
    required this.userId,
    this.existingProfile,
  }) : super(key: key);

  @override
  ConsumerState<DietaryProfileScreen> createState() =>
      _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends ConsumerState<DietaryProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sodiumController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _phosphorusController = TextEditingController();
  final _proteinController = TextEditingController();

  int _selectedCkdStage = 3; // Default to stage 3
  bool _isLoading = false;
  bool _showWarnings = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _selectedCkdStage = widget.existingProfile!.ckdStage;
      _sodiumController.text = widget.existingProfile!.dailySodiumLimit.toString();
      _potassiumController.text = widget.existingProfile!.dailyPotassiumLimit.toString();
      _phosphorusController.text = widget.existingProfile!.dailyPhosphorusLimit.toString();
      _proteinController.text = widget.existingProfile!.dailyProteinLimit.toString();
    } else {
      _loadRecommendedLimits();
    }
  }

  @override
  void dispose() {
    _sodiumController.dispose();
    _potassiumController.dispose();
    _phosphorusController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  void _loadRecommendedLimits() {
    final limits = kdogoLimitsByCkdStage[_selectedCkdStage]!;
    _sodiumController.text = limits.sodium.toInt().toString();
    _potassiumController.text = limits.potassium.toInt().toString();
    _phosphorusController.text = limits.phosphorus.toInt().toString();
    _proteinController.text = limits.protein.toInt().toString();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose Profile Picture',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF4A90E2),
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF50C9C3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF50C9C3),
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Delete current profile picture'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _profileImage = null);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final limits = kdogoLimitsByCkdStage[_selectedCkdStage]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF4A90E2).withOpacity(0.1),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF4A90E2),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A90E2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _showImageSourceDialog,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CKD Stage Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CKD Stage',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select your Chronic Kidney Disease stage as diagnosed by your healthcare provider.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedCkdStage,
                          decoration: InputDecoration(
                            labelText: 'CKD Stage',
                            prefixIcon: const Icon(Icons.medical_services),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: [1, 2, 3, 4, 5].map((stage) {
                            return DropdownMenuItem(
                              value: stage,
                              child: Text('Stage $stage'),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCkdStage = value!;
                                    _loadRecommendedLimits();
                                  });
                                },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadRecommendedLimits,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Load Recommended Limits'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[50],
                            foregroundColor: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Daily Limits Section
                Text(
                  'Daily Nutritional Limits',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your personalized daily limits. Values must be within KDIGO-recommended ranges.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),

                // Sodium
                _buildNutrientField(
                  controller: _sodiumController,
                  label: 'Sodium (mg)',
                  icon: Icons.water_drop,
                  referenceValue: limits.sodium,
                  unit: 'mg',
                ),
                const SizedBox(height: 16),

                // Potassium
                _buildNutrientField(
                  controller: _potassiumController,
                  label: 'Potassium (mg)',
                  icon: Icons.eco,
                  referenceValue: limits.potassium,
                  unit: 'mg',
                ),
                const SizedBox(height: 16),

                // Phosphorus
                _buildNutrientField(
                  controller: _phosphorusController,
                  label: 'Phosphorus (mg)',
                  icon: Icons.science,
                  referenceValue: limits.phosphorus,
                  unit: 'mg',
                ),
                const SizedBox(height: 16),

                // Protein
                _buildNutrientField(
                  controller: _proteinController,
                  label: 'Protein (g)',
                  icon: Icons.restaurant,
                  referenceValue: limits.protein,
                  unit: 'g',
                ),
                const SizedBox(height: 24),

                // Warning message
                if (_showWarnings)
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Some values are outside KDIGO-recommended ranges. Please consult your healthcare provider before proceeding.',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Disclaimer
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Important: These limits should be set in consultation with your healthcare provider. This app is for tracking purposes only and does not replace medical advice.',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double referenceValue,
    required String unit,
  }) {
    final minValue = referenceValue * kdogoMinMultiplier;
    final maxValue = referenceValue * kdogoMaxMultiplier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Recommended: ${referenceValue.toInt()} $unit',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a value';
            }
            final numValue = double.tryParse(value);
            if (numValue == null || numValue <= 0) {
              return 'Please enter a positive number';
            }
            if (numValue < minValue || numValue > maxValue) {
              setState(() => _showWarnings = true);
              return 'Outside KDIGO range (${minValue.toInt()}-${maxValue.toInt()} $unit)';
            }
            return null;
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 4),
        Text(
          'Valid range: ${minValue.toInt()} - ${maxValue.toInt()} $unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About KDIGO Limits'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'KDIGO (Kidney Disease: Improving Global Outcomes) provides evidence-based clinical practice guidelines for CKD management.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'The recommended limits vary by CKD stage:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...List.generate(5, (index) {
                final stage = index + 1;
                final limits = kdogoLimitsByCkdStage[stage]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Stage $stage:\n'
                    '  • Sodium: ${limits.sodium.toInt()} mg\n'
                    '  • Potassium: ${limits.potassium.toInt()} mg\n'
                    '  • Phosphorus: ${limits.phosphorus.toInt()} mg\n'
                    '  • Protein: ${limits.protein.toInt()} g',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
              const SizedBox(height: 12),
              const Text(
                'You can customize these limits within ±50% of the recommended values, but always consult your healthcare provider first.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _showWarnings = false);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = DietaryProfile(
        profileId: widget.existingProfile?.profileId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        dailySodiumLimit: double.parse(_sodiumController.text),
        dailyPotassiumLimit: double.parse(_potassiumController.text),
        dailyPhosphorusLimit: double.parse(_phosphorusController.text),
        dailyProteinLimit: double.parse(_proteinController.text),
        ckdStage: _selectedCkdStage,
        lastUpdated: DateTime.now(),
      );

      final profileRepo = ref.read(dietaryProfileRepositoryProvider);

      if (widget.existingProfile != null) {
        await profileRepo.updateDietaryProfile(profile);
      } else {
        await profileRepo.saveDietaryProfile(profile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dietary profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
