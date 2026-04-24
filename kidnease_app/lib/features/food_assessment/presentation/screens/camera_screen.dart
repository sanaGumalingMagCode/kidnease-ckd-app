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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Scan Food',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF4A90E2),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        automaticallyImplyLeading: true,
        // Ensure back button is visible
      ),
      body: SafeArea(
        child: _isProcessing ? _buildProcessingView() : _buildCameraView(),
      ),
    );
  }

  Widget _buildCameraView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Camera preview area
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A90E2).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Camera placeholder
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[900],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 80,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Camera Preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the camera button below to take a photo',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Overlay grid for better composition
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4A90E2),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'How to scan food',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionItem('📱', 'Food nutrition labels'),
                _buildInstructionItem('🍽️', 'Plated Filipino meals'),
                _buildInstructionItem('📦', 'Packaged food items'),
                _buildInstructionItem('💡', 'Ensure good lighting and clear focus'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Camera buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _captureAndAssess(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 24),
                    label: const Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4A90E2),
                      width: 2,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _captureAndAssess(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 24),
                    label: const Text(
                      'Gallery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF4A90E2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Processing animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Status message
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Progress bar
            if (_uploadProgress > 0) ...[
              Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _uploadProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${(_uploadProgress * 100).toInt()}% complete',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],

            const SizedBox(height: 32),
            Text(
              'Please wait while we analyze your food...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
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

// Custom painter for camera grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    final double thirdWidth = size.width / 3;
    canvas.drawLine(
      Offset(thirdWidth, 0),
      Offset(thirdWidth, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(thirdWidth * 2, 0),
      Offset(thirdWidth * 2, size.height),
      paint,
    );

    // Draw horizontal lines
    final double thirdHeight = size.height / 3;
    canvas.drawLine(
      Offset(0, thirdHeight),
      Offset(size.width, thirdHeight),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdHeight * 2),
      Offset(size.width, thirdHeight * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
