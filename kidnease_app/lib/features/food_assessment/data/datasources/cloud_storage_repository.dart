import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Abstract interface for cloud storage operations
abstract class CloudStorageRepository {
  /// Upload an image and return the download URL
  Future<String> uploadImage(File imageFile, String userId);

  /// Upload a profile photo and return the download URL
  Future<String> uploadProfilePhoto({required String userId, required File imageFile});

  /// Delete an image from storage
  Future<void> deleteImage(String imageUrl);

  /// Set lifecycle policy for automatic deletion
  Future<void> setLifecyclePolicy(int maxAgeHours);
}

/// Implementation of CloudStorageRepository using Firebase Storage
class FirebaseCloudStorageRepository implements CloudStorageRepository {
  final FirebaseStorage _storage;
  static const int _maxRetries = 3;
  static const Duration _uploadTimeout = Duration(seconds: 30);

  FirebaseCloudStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadProfilePhoto({required String userId, required File imageFile}) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        // Use consistent filename for profile photo (will overwrite old photo)
        final fileName = 'profile_photo.jpg';
        final path = 'users/$userId/profile/$fileName';

        logger.info('Uploading profile photo to Firebase Storage', context: {
          'path': path,
          'userId': userId,
          'attempt': retryCount + 1,
        });

        // Create reference
        final ref = _storage.ref().child(path);

        // Upload file with metadata
        final uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'userId': userId,
              'type': 'profile_photo',
            },
          ),
        );

        // Wait for upload with timeout
        final snapshot = await uploadTask.timeout(
          _uploadTimeout,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );

        // Get download URL
        final downloadUrl = await ref.getDownloadURL();

        logger.info('Profile photo uploaded successfully', context: {
          'path': path,
          'url': downloadUrl,
          'size': snapshot.totalBytes,
        });

        return downloadUrl;
      } on FirebaseException catch (e) {
        lastException = e;
        logger.error('Firebase Storage error uploading profile photo', error: e, context: {
          'code': e.code,
          'attempt': retryCount + 1,
        });

        if (e.code == 'quota-exceeded') {
          throw StorageException.quotaExceeded();
        } else if (e.code == 'unauthorized' || e.code == 'unauthenticated') {
          throw StorageException.permissionDenied();
        } else if (e.code == 'canceled') {
          throw const StorageException('Upload canceled');
        }

        if (e.code == 'unknown' || e.code == 'unavailable') {
          retryCount++;
          if (retryCount < _maxRetries) {
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
        }

        throw StorageException.uploadFailed();
      } catch (e, stackTrace) {
        lastException = e as Exception?;
        logger.error('Unexpected profile photo upload error', error: e, stackTrace: stackTrace);

        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }

        throw StorageException('Profile photo upload failed: ${e.toString()}');
      }
    }

    throw StorageException(
      'Profile photo upload failed after $_maxRetries attempts: ${lastException?.toString()}',
    );
  }

  @override
  Future<String> uploadImage(File imageFile, String userId) async {
    int retryCount = 0;
    Exception? lastException;

    while (retryCount < _maxRetries) {
      try {
        // Generate unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '$timestamp.jpg';
        final path = 'users/$userId/food_images/$fileName';

        logger.info('Uploading image to Firebase Storage', context: {
          'path': path,
          'userId': userId,
          'attempt': retryCount + 1,
        });

        // Create reference
        final ref = _storage.ref().child(path);

        // Upload file with metadata
        final uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedAt': DateTime.now().toIso8601String(),
              'userId': userId,
            },
          ),
        );

        // Wait for upload with timeout
        final snapshot = await uploadTask.timeout(
          _uploadTimeout,
          onTimeout: () {
            throw NetworkException.timeout();
          },
        );

        // Get download URL
        final downloadUrl = await ref.getDownloadURL();

        logger.info('Image uploaded successfully', context: {
          'path': path,
          'url': downloadUrl,
          'size': snapshot.totalBytes,
        });

        return downloadUrl;
      } on FirebaseException catch (e) {
        lastException = e;
        logger.error('Firebase Storage error', error: e, context: {
          'code': e.code,
          'attempt': retryCount + 1,
        });

        // Handle specific Firebase errors
        if (e.code == 'quota-exceeded') {
          throw StorageException.quotaExceeded();
        } else if (e.code == 'unauthorized' || e.code == 'unauthenticated') {
          throw StorageException.permissionDenied();
        } else if (e.code == 'canceled') {
          throw const StorageException('Upload canceled');
        }

        // Retry for network errors
        if (e.code == 'unknown' || e.code == 'unavailable') {
          retryCount++;
          if (retryCount < _maxRetries) {
            // Exponential backoff
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
        }

        throw StorageException.uploadFailed();
      } catch (e, stackTrace) {
        lastException = e as Exception?;
        logger.error('Unexpected upload error', error: e, stackTrace: stackTrace, context: {
          'attempt': retryCount + 1,
        });

        retryCount++;
        if (retryCount < _maxRetries) {
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }

        throw StorageException('Upload failed: ${e.toString()}');
      }
    }

    // If we get here, all retries failed
    throw StorageException(
      'Upload failed after $_maxRetries attempts: ${lastException?.toString()}',
    );
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = _extractPathFromUrl(imageUrl);

      if (path == null) {
        logger.warning('Could not extract path from URL', context: {
          'url': imageUrl,
        });
        return;
      }

      logger.info('Deleting image from Firebase Storage', context: {
        'path': path,
      });

      // Delete the file
      final ref = _storage.ref().child(path);
      await ref.delete();

      logger.info('Image deleted successfully', context: {
        'path': path,
      });
    } on FirebaseException catch (e) {
      // If file doesn't exist, that's okay (already deleted)
      if (e.code == 'object-not-found') {
        logger.info('Image already deleted or does not exist', context: {
          'url': imageUrl,
        });
        return;
      }

      logger.error('Firebase Storage deletion error', error: e, context: {
        'code': e.code,
        'url': imageUrl,
      });

      if (e.code == 'unauthorized' || e.code == 'unauthenticated') {
        throw StorageException.permissionDenied();
      }

      throw StorageException('Failed to delete image: ${e.message}');
    } catch (e, stackTrace) {
      logger.error('Unexpected deletion error', error: e, stackTrace: stackTrace);
      throw StorageException('Failed to delete image: ${e.toString()}');
    }
  }

  @override
  Future<void> setLifecyclePolicy(int maxAgeHours) async {
    // Note: Lifecycle policies are typically set via Firebase Console or gsutil CLI
    // This method is a placeholder for documentation purposes
    logger.info('Lifecycle policy should be set via Firebase Console', context: {
      'maxAgeHours': maxAgeHours,
      'instructions': 'Use storage-lifecycle.json configuration file',
    });
  }

  /// Extract storage path from Firebase Storage URL
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Firebase Storage URLs have format:
      // https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?alt=media&token={token}
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 4) {
        return null;
      }

      // Find the 'o' segment and get everything after it
      final oIndex = pathSegments.indexOf('o');
      if (oIndex == -1 || oIndex == pathSegments.length - 1) {
        return null;
      }

      // Join remaining segments and decode
      final encodedPath = pathSegments.sublist(oIndex + 1).join('/');
      return Uri.decodeComponent(encodedPath);
    } catch (e) {
      logger.error('Error extracting path from URL', error: e, context: {
        'url': url,
      });
      return null;
    }
  }

  /// Get metadata for an image
  Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      final path = _extractPathFromUrl(imageUrl);
      if (path == null) {
        return null;
      }

      final ref = _storage.ref().child(path);
      return await ref.getMetadata();
    } catch (e) {
      logger.error('Error getting image metadata', error: e);
      return null;
    }
  }
}
