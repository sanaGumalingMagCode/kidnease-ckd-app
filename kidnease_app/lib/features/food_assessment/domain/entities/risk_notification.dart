/// Risk Notification entity representing a user notification about dietary risk
class RiskNotification {
  final String notificationId;
  final String userId;
  final String assessmentId;
  final String severityLevel; // "high" or "safe"
  final String displayMessage;
  final DateTime timestamp;
  final bool dismissed;

  const RiskNotification({
    required this.notificationId,
    required this.userId,
    required this.assessmentId,
    required this.severityLevel,
    required this.displayMessage,
    required this.timestamp,
    this.dismissed = false,
  });

  RiskNotification copyWith({
    String? notificationId,
    String? userId,
    String? assessmentId,
    String? severityLevel,
    String? displayMessage,
    DateTime? timestamp,
    bool? dismissed,
  }) {
    return RiskNotification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      assessmentId: assessmentId ?? this.assessmentId,
      severityLevel: severityLevel ?? this.severityLevel,
      displayMessage: displayMessage ?? this.displayMessage,
      timestamp: timestamp ?? this.timestamp,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RiskNotification &&
        other.notificationId == notificationId &&
        other.userId == userId &&
        other.assessmentId == assessmentId &&
        other.severityLevel == severityLevel &&
        other.displayMessage == displayMessage &&
        other.timestamp == timestamp &&
        other.dismissed == dismissed;
  }

  @override
  int get hashCode {
    return notificationId.hashCode ^
        userId.hashCode ^
        assessmentId.hashCode ^
        severityLevel.hashCode ^
        displayMessage.hashCode ^
        timestamp.hashCode ^
        dismissed.hashCode;
  }

  @override
  String toString() {
    return 'RiskNotification(notificationId: $notificationId, userId: $userId, assessmentId: $assessmentId, severityLevel: $severityLevel, displayMessage: $displayMessage, timestamp: $timestamp, dismissed: $dismissed)';
  }
}
