import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Abstract interface for image capture operations
abstract class ImageCaptureService {
  /// Capture an image from camera
  Future<File> captureImage();

  /// Compress an image to reduce file size
  Future<File> compressImage(File originalImage, {int maxSizeKB = 2048});

  /// Validate image quality for OCR readability
  Future<bool> validateImageQuality(File image);
}

/// Implementation of ImageCaptureService using image_picker and flutter_image_compress
class CameraImageCaptureService implements ImageCaptureService {
  final ImagePicker _picker;

  CameraImageCaptureService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<File> captureImage() async {
    try {
      logger.info('Attempting to open camera...');
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        logger.warning('Camera capture canceled by user');
        throw CameraException('Camera capture was canceled');
      }

      final capturedFile = File(photo.path);
      final fileSize = await capturedFile.length();

      logger.info('Image captured successfully', context: {
        'path': photo.path,
        'size': fileSize,
      });

      return capturedFile;
    } on CameraException {
      rethrow;
    } catch (e, stackTrace) {
      logger.error('Error capturing image', error: e, stackTrace: stackTrace);

      // Check for specific error types
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('camera_access_denied') ||
          errorString.contains('permission') ||
          errorString.contains('denied')) {
        throw CameraException('Camera permission denied. Please enable camera access in settings.');
      }

      if (errorString.contains('camera not available') ||
          errorString.contains('no camera')) {
        throw CameraException('Camera not available. This device may not have a camera or the camera is being used by another app.');
      }

      throw CameraException('Failed to capture image. Please try using gallery instead.');
    }
  }

  @override
  Future<File> compressImage(File originalImage, {int maxSizeKB = 2048}) async {
    try {
      final originalSize = await originalImage.length();
      logger.info('Starting image compression', context: {
        'originalSize': originalSize,
        'maxSizeKB': maxSizeKB,
      });

      // If already under max size, return original
      if (originalSize <= maxSizeKB * 1024) {
        logger.info('Image already under max size, skipping compression');
        return originalImage;
      }

      // Calculate target quality based on size ratio
      final targetSize = maxSizeKB * 1024;
      final sizeRatio = targetSize / originalSize;
      int quality = (sizeRatio * 100).clamp(50, 85).toInt();

      // Compress image
      final compressedPath = originalImage.path.replaceAll('.jpg', '_compressed.jpg');
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalImage.path,
        compressedPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        throw const StorageException('Image compression failed');
      }

      final compressedSize = await File(compressedFile.path).length();
      logger.info('Image compressed successfully', context: {
        'originalSize': originalSize,
        'compressedSize': compressedSize,
        'quality': quality,
        'reduction': '${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%',
      });

      // If still too large, compress again with lower quality
      if (compressedSize > maxSizeKB * 1024 && quality > 50) {
        logger.warning('Compressed image still too large, compressing again');
        return await compressImage(File(compressedFile.path), maxSizeKB: maxSizeKB);
      }

      return File(compressedFile.path);
    } catch (e, stackTrace) {
      logger.error('Error compressing image', error: e, stackTrace: stackTrace);
      throw StorageException('Failed to compress image: ${e.toString()}');
    }
  }

  @override
  Future<bool> validateImageQuality(File image) async {
    try {
      // Check file exists
      if (!await image.exists()) {
        logger.warning('Image file does not exist');
        return false;
      }

      // Check file size (should be > 0)
      final size = await image.length();
      if (size == 0) {
        logger.warning('Image file is empty');
        return false;
      }

      // Get image dimensions
      final imageData = await image.readAsBytes();
      
      // Basic validation: file should be at least 10KB for meaningful content
      if (size < 10 * 1024) {
        logger.warning('Image file too small', context: {'size': size});
        return false;
      }

      // Check if it's a valid image format (JPEG/PNG)
      if (!image.path.toLowerCase().endsWith('.jpg') &&
          !image.path.toLowerCase().endsWith('.jpeg') &&
          !image.path.toLowerCase().endsWith('.png')) {
        logger.warning('Invalid image format', context: {'path': image.path});
        return false;
      }

      logger.info('Image quality validation passed', context: {
        'size': size,
        'path': image.path,
      });

      return true;
    } catch (e, stackTrace) {
      logger.error('Error validating image quality', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Pick image from gallery (alternative to camera)
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (photo == null) {
        return null;
      }

      logger.info('Image picked from gallery', context: {
        'path': photo.path,
      });

      return File(photo.path);
    } catch (e, stackTrace) {
      logger.error('Error picking image from gallery', error: e, stackTrace: stackTrace);
      throw CameraException('Failed to pick image: ${e.toString()}');
    }
  }
}
