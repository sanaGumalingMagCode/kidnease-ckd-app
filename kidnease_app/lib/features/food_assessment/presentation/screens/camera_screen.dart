import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/providers/providers.dart';
import '../../../dietary_profile/domain/entities/dietary_profile.dart';
import '../../domain/usecases/capture_and_assess_food_usecase.dart';
import '../widgets/risk_notification_widget.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final String userId;
  final DietaryProfile userProfile;

  const CameraScreen({
    Key? key,
    required this.userId,
    required this.userProfile,
  }) : super(key: key);

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _isProcessing = false;
  double _uploadProgress = 0.0;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Food'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  Icons.camera_alt,
                  size: 120,
                  color: _isProcessing ? Colors.grey : Colors.blue,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Scan Your Food',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Instructions
                Text(
                  'Take a photo of:\n'
                  '• Food nutrition labels\n'
                  '• Plated Filipino meals\n'
                  '• Packaged food items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Processing indicator
                if (_isProcessing) ...[
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _uploadProgress > 0 ? _uploadProgress : null,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // Camera button
                if (!_isProcessing)
                  ElevatedButton.icon(
                    onPressed: () => _captureAndAssess(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Take Photo',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Gallery button
                if (!_isProcessing)
                  OutlinedButton.icon(
                    onPressed: () => _captureAndAssess(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 24),
                    label: const Text(
                      'Choose from Gallery',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Tips
                if (!_isProcessing)
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tip: Ensure good lighting and clear focus for best results',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                              ),
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
      ),
    );
  }

  Future<void> _captureAndAssess(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Preparing...';
    });

    try {
      final useCase = ref.read(captureAndAssessFoodUseCaseProvider);

      // Update status messages during processing
      _updateStatus('Capturing image...');
      await Future.delayed(const Duration(milliseconds: 500));

      _updateStatus('Compressing image...');
      await Future.delayed(const Duration(milliseconds: 500));

      _updateStatus('Uploading to cloud...');
      setState(() => _uploadProgress = 0.3);
      await Future.delayed(const Duration(milliseconds: 500));

      _updateStatus('Analyzing with AI...');
      setState(() => _uploadProgress = 0.6);

      // Execute the complete assessment flow
      final result = await useCase.execute(
        userId: widget.userId,
        userProfile: widget.userProfile,
        source: source,
      );

      _updateStatus('Assessment complete!');
      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        // Show notification
        await _showRiskNotification(result);

        // Navigate back to dashboard
        Navigator.of(context).pop(result);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Validation Error',
          e.message,
          icon: Icons.warning_amber,
          color: Colors.orange,
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Network Error',
          e.message,
          icon: Icons.wifi_off,
          color: Colors.red,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        _showErrorDialog(
          'API Error',
          e.message,
          icon: Icons.cloud_off,
          color: Colors.red,
        );
      }
    } on StorageException catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Storage Error',
          e.message,
          icon: Icons.storage,
          color: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Unexpected Error',
          'An unexpected error occurred: $e',
          icon: Icons.error,
          color: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _uploadProgress = 0.0;
          _statusMessage = '';
        });
      }
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  Future<void> _showRiskNotification(AssessmentResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RiskNotificationWidget(
        riskLevel: result.riskLevel,
        foodName: result.assessment.detectedFoodName,
        explanation: result.explanation,
        filipinoAlternatives: result.filipinoAlternatives,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showErrorDialog(
    String title,
    String message, {
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
