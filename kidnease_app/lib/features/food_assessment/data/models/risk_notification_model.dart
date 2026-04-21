import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/risk_notification.dart';

/// Data Transfer Object for RiskNotification entity
class RiskNotificationModel {
  final String notificationId;
  final String userId;
  final String assessmentId;
  final String severityLevel;
  final String displayMessage;
  final Timestamp timestamp;
  final bool dismissed;

  const RiskNotificationModel({
    required this.notificationId,
    required this.userId,
    required this.assessmentId,
    required this.severityLevel,
    required this.displayMessage,
    required this.timestamp,
    this.dismissed = false,
  });

  factory RiskNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RiskNotificationModel(
      notificationId: data['notificationId'] as String,
      userId: data['userId'] as String,
      assessmentId: data['assessmentId'] as String,
      severityLevel: data['severityLevel'] as String,
      displayMessage: data['displayMessage'] as String,
      timestamp: data['timestamp'] as Timestamp,
      dismissed: data['dismissed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'assessmentId': assessmentId,
      'severityLevel': severityLevel,
      'displayMessage': displayMessage,
      'timestamp': timestamp,
      'dismissed': dismissed,
    };
  }

  RiskNotification toDomain() {
    return RiskNotification(
      notificationId: notificationId,
      userId: userId,
      assessmentId: assessmentId,
      severityLevel: severityLevel,
      displayMessage: displayMessage,
      timestamp: timestamp.toDate(),
      dismissed: dismissed,
    );
  }

  static RiskNotificationModel fromDomain(RiskNotification notification) {
    return RiskNotificationModel(
      notificationId: notification.notificationId,
      userId: notification.userId,
      assessmentId: notification.assessmentId,
      severityLevel: notification.severityLevel,
      displayMessage: notification.displayMessage,
      timestamp: Timestamp.fromDate(notification.timestamp),
      dismissed: notification.dismissed,
    );
  }
}
